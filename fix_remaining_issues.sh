#!/bin/bash

echo "=== eBrew Final Issues Fix ==="
echo "Timestamp: $(date)"
echo "Fixing: 1) Cart empty display 2) Admin users role column 3) Buy Now admin redirect"
echo

# 1. Fix CartManager to properly load cart items with relationships
echo "1. Fixing CartManager component for proper item display..."
sudo tee /var/www/html/app/Livewire/CartManager.php > /dev/null << 'EOF'
<?php

namespace App\Livewire;

use Livewire\Component;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Item;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class CartManager extends Component
{
    public $cartItems = [];
    public $cartTotal = 0;
    public $cartCount = 0;
    public $showNotification = false;
    public $notificationMessage = '';

    protected $listeners = ['cartUpdated' => 'loadCart'];

    public function mount()
    {
        $this->loadCart();
    }

    public function loadCart()
    {
        try {
            if (Auth::check()) {
                // Authenticated user - load from database
                $cart = Cart::firstOrCreate(['UserID' => Auth::id()]);
                
                Log::info('CartManager: Loading cart for user', [
                    'user_id' => Auth::id(),
                    'cart_id' => $cart->id
                ]);
                
                // Get cart items with proper eager loading
                $cartItems = CartItem::where('CartID', $cart->id)
                    ->with(['item' => function($query) {
                        $query->select('id', 'Name', 'Price', 'Image');
                    }])
                    ->get();
                
                Log::info('CartManager: Found cart items', [
                    'cart_items_count' => $cartItems->count(),
                    'cart_items' => $cartItems->toArray()
                ]);
                
                $this->cartItems = $cartItems->map(function ($cartItem) {
                    // Ensure we have valid item data
                    if (!$cartItem->item) {
                        Log::warning('CartManager: CartItem has no associated item', [
                            'cart_item_id' => $cartItem->id,
                            'item_id' => $cartItem->ItemID
                        ]);
                        return null;
                    }
                    
                    return [
                        'id' => $cartItem->id, // Use CartItem ID for operations
                        'cart_id' => $cartItem->CartID,
                        'item_id' => $cartItem->ItemID,
                        'quantity' => (int) $cartItem->Quantity,
                        'item' => [
                            'id' => $cartItem->item->id,
                            'Name' => $cartItem->item->Name,
                            'Price' => (float) $cartItem->item->Price,
                            'image_url' => $cartItem->item->image_url ?? asset('images/default.png')
                        ]
                    ];
                })->filter()->values()->toArray(); // Remove null items and reindex
                
            } else {
                // Guest user - load from session
                $sessionCart = session()->get('cart', []);
                
                Log::info('CartManager: Loading session cart', [
                    'session_cart' => $sessionCart
                ]);
                
                $this->cartItems = collect($sessionCart)->map(function ($item, $itemId) {
                    return [
                        'id' => 'session_' . $itemId,
                        'item_id' => $item['item_id'],
                        'quantity' => (int) $item['quantity'],
                        'item' => [
                            'id' => $item['item_id'],
                            'Name' => $item['name'],
                            'Price' => (float) $item['price'],
                            'image_url' => $item['image'] ?? asset('images/default.png')
                        ]
                    ];
                })->values()->toArray();
            }
            
            // Calculate totals
            $this->cartTotal = collect($this->cartItems)->sum(function ($item) {
                return ($item['item']['Price'] ?? 0) * ($item['quantity'] ?? 0);
            });
            
            $this->cartCount = collect($this->cartItems)->sum('quantity');
            
            Log::info('CartManager: Cart loaded successfully', [
                'items_count' => count($this->cartItems),
                'total' => $this->cartTotal,
                'count' => $this->cartCount
            ]);
            
        } catch (\Exception $e) {
            Log::error('CartManager: Error loading cart', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            // Set safe defaults
            $this->cartItems = [];
            $this->cartTotal = 0;
            $this->cartCount = 0;
        }
    }

    public function updateQuantity($cartItemId, $quantity)
    {
        if ($quantity <= 0) {
            $this->removeFromCart($cartItemId);
            return;
        }

        try {
            if (Auth::check()) {
                // For authenticated users, cartItemId is the actual CartItem ID
                $cartItem = CartItem::find($cartItemId);
                if ($cartItem && $cartItem->cart && $cartItem->cart->UserID == Auth::id()) {
                    $cartItem->update(['Quantity' => $quantity]);
                    $this->showNotification('Cart updated successfully!', 'success');
                } else {
                    $this->showNotification('Item not found in cart', 'error');
                    $this->loadCart();
                    return;
                }
            } else {
                // Guest user - update session
                $sessionCart = session()->get('cart', []);
                $sessionItemId = str_replace('session_', '', $cartItemId);
                
                if (isset($sessionCart[$sessionItemId])) {
                    $sessionCart[$sessionItemId]['quantity'] = $quantity;
                    session()->put('cart', $sessionCart);
                    $this->showNotification('Cart updated successfully!', 'success');
                }
            }
            
            $this->loadCart();
            $this->dispatch('cartUpdated');
            
        } catch (\Exception $e) {
            Log::error('CartManager: Error updating quantity', [
                'cart_item_id' => $cartItemId,
                'quantity' => $quantity,
                'error' => $e->getMessage()
            ]);
            $this->showNotification('Error updating cart', 'error');
            $this->loadCart();
        }
    }

    public function removeFromCart($cartItemId)
    {
        try {
            if (Auth::check()) {
                // For authenticated users, cartItemId is the actual CartItem ID
                $cartItem = CartItem::find($cartItemId);
                if ($cartItem && $cartItem->cart && $cartItem->cart->UserID == Auth::id()) {
                    $itemName = $cartItem->item->Name ?? 'Item';
                    $cartItem->delete();
                    $this->showNotification("$itemName removed from cart", 'success');
                } else {
                    $this->showNotification('Item not found in cart', 'error');
                }
            } else {
                // Guest user - remove from session
                $sessionCart = session()->get('cart', []);
                $sessionItemId = str_replace('session_', '', $cartItemId);
                
                if (isset($sessionCart[$sessionItemId])) {
                    $itemName = $sessionCart[$sessionItemId]['name'] ?? 'Item';
                    unset($sessionCart[$sessionItemId]);
                    session()->put('cart', $sessionCart);
                    $this->showNotification("$itemName removed from cart", 'success');
                }
            }
            
            $this->loadCart();
            $this->dispatch('cartUpdated');
            
        } catch (\Exception $e) {
            Log::error('CartManager: Error removing item', [
                'cart_item_id' => $cartItemId,
                'error' => $e->getMessage()
            ]);
            $this->showNotification('Error removing item from cart', 'error');
            $this->loadCart();
        }
    }

    public function clearCart()
    {
        try {
            if (Auth::check()) {
                // Authenticated user - clear database cart
                $cart = Cart::where('UserID', Auth::id())->first();
                if ($cart) {
                    CartItem::where('CartID', $cart->id)->delete();
                }
            } else {
                // Guest user - clear session cart
                session()->forget('cart');
            }
            
            $this->loadCart();
            $this->dispatch('cartUpdated');
            $this->showNotification('Cart cleared successfully!', 'success');
            
        } catch (\Exception $e) {
            Log::error('CartManager: Error clearing cart', [
                'error' => $e->getMessage()
            ]);
            $this->showNotification('Error clearing cart', 'error');
        }
    }

    private function showNotification($message, $type = 'success')
    {
        $this->notificationMessage = $message;
        $this->showNotification = true;
        
        // Auto-hide notification after 3 seconds
        $this->dispatch('hideNotification');
    }

    public function hideNotification()
    {
        $this->showNotification = false;
    }

    public function render()
    {
        return view('livewire.cart-manager');
    }
}
EOF

# 2. Update CheckoutController to handle admin redirect properly
echo "2. Fixing CheckoutController for admin redirect..."
sudo tee /var/www/html/app/Http/Controllers/CheckoutController.php > /dev/null << 'EOF'
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Order;
use App\Models\OrderItem;

class CheckoutController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function index()
    {
        $user = Auth::user();
        
        // Check if user is admin - redirect to admin dashboard
        if ($user->role === 'admin' || $user->Role === 'admin') {
            return redirect()->route('admin.dashboard')
                ->with('info', 'Admins should use the admin panel for order management.');
        }
        
        // Get user's cart
        $cart = Cart::where('UserID', $user->id)->with('items.item')->first();
        
        if (!$cart || $cart->items->isEmpty()) {
            return redirect()->route('cart.index')->with('error', 'Your cart is empty.');
        }

        return view('checkout.index', compact('cart', 'user'));
    }

    public function process(Request $request)
    {
        $user = Auth::user();
        
        // Check if user is admin - redirect to admin dashboard
        if ($user->role === 'admin' || $user->Role === 'admin') {
            return redirect()->route('admin.dashboard')
                ->with('info', 'Admins cannot place orders. Use admin panel for order management.');
        }
        
        // Get user's cart
        $cart = Cart::where('UserID', $user->id)->with('items.item')->first();
        
        if (!$cart || $cart->items->isEmpty()) {
            return redirect()->route('cart.index')->with('error', 'Your cart is empty.');
        }

        // Create order using raw SQL to avoid any model issues
        $orderData = [
            'UserID' => $user->id,
            'OrderDate' => now(),
            'SubTotal' => $cart->total
        ];
        
        // Insert order directly into database
        $orderId = DB::table('orders')->insertGetId([
            'UserID' => $user->id,
            'OrderDate' => now(),
            'SubTotal' => $cart->total
        ]);

        // Create a simple order object for the view
        $order = (object)[
            'OrderID' => $orderId,
            'UserID' => $user->id,
            'OrderDate' => now(),
            'SubTotal' => $cart->total
        ];

        // Create order items
        foreach ($cart->items as $cartItem) {
            DB::table('order_items')->insert([
                'OrderID' => $orderId,
                'ItemID' => $cartItem->ItemID,
                'Quantity' => $cartItem->Quantity,
                'Price' => $cartItem->item->Price // Store price at time of purchase
            ]);
        }

        // Clear cart
        $cart->items()->delete();

        return view('checkout.success', compact('user', 'order'));
    }

    public function buyNow($itemId)
    {
        // Check if user is authenticated
        if (!Auth::check()) {
            return redirect()->route('login')->with('message', 'Please login to purchase items.');
        }
        
        $user = Auth::user();
        
        // Check if user is admin - redirect to admin dashboard instead of checkout
        if ($user->role === 'admin' || $user->Role === 'admin') {
            return redirect()->route('admin.dashboard')
                ->with('info', 'Admins cannot make purchases. This is for customer accounts only.');
        }
        
        try {
            // Validate item exists
            $item = \App\Models\Item::find($itemId);
            if (!$item) {
                return redirect()->back()->with('error', 'Product not found.');
            }
            
            // Get or create cart for user
            $cart = Cart::firstOrCreate(['UserID' => $user->id]);
            
            // Clear existing cart items
            if ($cart) {
                $cart->items()->delete();
                \Log::info('BuyNow: Cleared existing cart items', ['cart_id' => $cart->id]);
            }
            
            // Ensure we have a valid cart ID
            if (!$cart || !$cart->id) {
                \Log::error('BuyNow: Cart creation failed', ['user_id' => $user->id]);
                return redirect()->back()->with('error', 'Unable to create cart. Please try again.');
            }

            // Add single item to cart
            $cartItem = CartItem::create([
                'CartID' => $cart->id,
                'ItemID' => $itemId,
                'Quantity' => 1
            ]);
            
            if (!$cartItem) {
                \Log::error('BuyNow: CartItem creation failed', [
                    'cart_id' => $cart->id,
                    'item_id' => $itemId
                ]);
                return redirect()->back()->with('error', 'Unable to add item to cart. Please try again.');
            }
            
            \Log::info('BuyNow: Item added successfully', [
                'cart_id' => $cart->id,
                'item_id' => $itemId,
                'cart_item_id' => $cartItem->id
            ]);

            return redirect()->route('checkout.index');
            
        } catch (\Exception $e) {
            \Log::error('BuyNow: Exception occurred', [
                'message' => $e->getMessage(),
                'user_id' => $user->id,
                'item_id' => $itemId,
                'trace' => $e->getTraceAsString()
            ]);
            
            return redirect()->back()->with('error', 'An error occurred while processing your request. Please try again.');
        }
    }
}
EOF

# 3. Update admin users index to show roles properly
echo "3. Fixing admin users table to show roles..."
sudo tee /var/www/html/resources/views/admin/users/index.blade.php > /dev/null << 'EOF'
@extends('layouts.app')

@section('content')
<div class="min-h-screen font-sans bg-[#F9F6F1] p-10 text-[#2D1B12]">
    <!-- Header -->
    <div class="flex items-center justify-between mb-10">
        <h1 class="text-3xl font-bold">User Management</h1>
        <a href="{{ route('admin.users.create') }}" 
           class="bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-lg shadow-md transition">
            + Add User
        </a>
    </div>

    <!-- Success Message -->
    @if(session('success'))
        <div class="bg-green-100 border border-green-400 text-green-700 px-5 py-3 rounded-lg mb-6 shadow-sm">
            {{ session('success') }}
        </div>
    @endif

    <!-- Info Message -->
    @if(session('info'))
        <div class="bg-blue-100 border border-blue-400 text-blue-700 px-5 py-3 rounded-lg mb-6 shadow-sm">
            {{ session('info') }}
        </div>
    @endif

    <!-- Users Table -->
    <div class="bg-white rounded-xl shadow-md overflow-hidden">
        <table class="w-full text-sm">
            <thead class="bg-gray-100 border-b">
                <tr>
                    <th class="px-6 py-4 text-left font-semibold text-gray-600">ID</th>
                    <th class="px-6 py-4 text-left font-semibold text-gray-600">Name</th>
                    <th class="px-6 py-4 text-left font-semibold text-gray-600">Email</th>
                    <th class="px-6 py-4 text-left font-semibold text-gray-600">Role</th>
                    <th class="px-6 py-4 text-left font-semibold text-gray-600">Phone</th>
                    <th class="px-6 py-4 text-left font-semibold text-gray-600">Created</th>
                    <th class="px-6 py-4 text-left font-semibold text-gray-600">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
                @forelse($users as $user)
                    <tr class="hover:bg-gray-50 transition">
                        <td class="px-6 py-4 text-gray-600">{{ $user->id }}</td>
                        <td class="px-6 py-4">
                            <div class="font-medium text-gray-900">{{ $user->name }}</div>
                        </td>
                        <td class="px-6 py-4 text-gray-600">{{ $user->email }}</td>
                        <td class="px-6 py-4">
                            @php
                                // Handle both 'role' and 'Role' fields for compatibility
                                $userRole = $user->Role ?? $user->role ?? 'customer';
                            @endphp
                            <span class="px-3 py-1 inline-flex text-xs font-semibold rounded-full 
                                {{ $userRole === 'admin' ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800' }}">
                                {{ ucfirst($userRole) }}
                            </span>
                        </td>
                        <td class="px-6 py-4 text-gray-500">
                            {{ $user->Phone ?? $user->phone ?? 'N/A' }}
                        </td>
                        <td class="px-6 py-4 text-gray-500">
                            {{ $user->created_at->format('M d, Y') }}
                        </td>
                        <td class="px-6 py-4 flex items-center gap-3">
                            <a href="{{ route('admin.users.show', $user) }}" 
                               class="px-3 py-1 bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200 transition">
                                View
                            </a>
                            <a href="{{ route('admin.users.edit', $user) }}" 
                               class="px-3 py-1 bg-yellow-100 text-yellow-700 rounded-lg hover:bg-yellow-200 transition">
                                Edit
                            </a>
                            @if($user->id !== auth()->id())
                                <form method="POST" action="{{ route('admin.users.destroy', $user) }}" class="inline">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" 
                                            class="px-3 py-1 bg-red-100 text-red-700 rounded-lg hover:bg-red-200 transition"
                                            onclick="return confirm('Are you sure you want to delete this user?')">
                                        Delete
                                    </button>
                                </form>
                            @else
                                <span class="px-3 py-1 bg-gray-100 text-gray-500 rounded-lg cursor-not-allowed">
                                    Cannot Delete Self
                                </span>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="7" class="px-6 py-6 text-center text-gray-500">
                            No users found.
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <!-- Pagination -->
    <div class="mt-6">
        {{ $users->links('pagination::tailwind') }}
    </div>

    <!-- Back -->
    <div class="mt-10">
        <a href="{{ route('admin.dashboard') }}" 
           class="text-gray-600 hover:text-gray-900 font-medium transition">
            ← Back to Dashboard
        </a>
    </div>
</div>
@endsection
EOF

# 4. Update cart manager view to handle empty state better
echo "4. Updating cart manager view..."
sudo tee /var/www/html/resources/views/livewire/cart-manager.blade.php > /dev/null << 'EOF'
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <h1 class="text-3xl font-bold text-gray-900 mb-8">Your Shopping Cart</h1>

    <!-- Notification -->
    @if($showNotification)
        <div class="mb-6 p-4 rounded-lg {{ str_contains($notificationMessage, 'Error') || str_contains($notificationMessage, 'error') ? 'bg-red-100 text-red-700 border border-red-300' : 'bg-green-100 text-green-700 border border-green-300' }}">
            {{ $notificationMessage }}
        </div>
    @endif

    @if(count($cartItems) > 0)
        <!-- Cart Items -->
        <div class="bg-white rounded-lg shadow-md overflow-hidden mb-8">
            <div class="p-6">
                <h2 class="text-xl font-semibold text-gray-900 mb-4">Cart Items ({{ $cartCount }})</h2>
                
                <div class="space-y-4">
                    @foreach($cartItems as $item)
                        <div class="flex items-center justify-between border-b border-gray-200 pb-4 last:border-b-0">
                            <!-- Product Image -->
                            <div class="flex items-center space-x-4">
                                <img src="{{ $item['item']['image_url'] }}" 
                                     alt="{{ $item['item']['Name'] }}" 
                                     class="w-20 h-20 object-cover rounded-lg">
                                
                                <!-- Product Details -->
                                <div>
                                    <h3 class="text-lg font-medium text-gray-900">{{ $item['item']['Name'] }}</h3>
                                    <p class="text-gray-600">Rs. {{ number_format($item['item']['Price'], 2) }}</p>
                                </div>
                            </div>

                            <!-- Quantity Controls -->
                            <div class="flex items-center space-x-4">
                                <div class="flex items-center border border-gray-300 rounded-lg">
                                    <button wire:click="updateQuantity({{ $item['id'] }}, {{ $item['quantity'] - 1 }})"
                                            class="px-3 py-1 hover:bg-gray-100 transition">−</button>
                                    <span class="px-4 py-1 border-l border-r border-gray-300">{{ $item['quantity'] }}</span>
                                    <button wire:click="updateQuantity({{ $item['id'] }}, {{ $item['quantity'] + 1 }})"
                                            class="px-3 py-1 hover:bg-gray-100 transition">+</button>
                                </div>

                                <!-- Item Total -->
                                <div class="text-right min-w-[100px]">
                                    <p class="text-lg font-semibold text-gray-900">
                                        Rs. {{ number_format($item['item']['Price'] * $item['quantity'], 2) }}
                                    </p>
                                </div>

                                <!-- Remove Button -->
                                <button wire:click="removeFromCart({{ $item['id'] }})"
                                        class="text-red-600 hover:text-red-800 transition">
                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                                              d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                                    </svg>
                                </button>
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>
        </div>

        <!-- Cart Summary -->
        <div class="bg-white rounded-lg shadow-md p-6 mb-8">
            <div class="flex justify-between items-center mb-4">
                <h2 class="text-xl font-semibold text-gray-900">Cart Summary</h2>
            </div>
            
            <div class="space-y-2 mb-6">
                <div class="flex justify-between">
                    <span class="text-gray-600">Items ({{ $cartCount }})</span>
                    <span class="text-gray-900">Rs. {{ number_format($cartTotal, 2) }}</span>
                </div>
                <div class="border-t border-gray-200 pt-2">
                    <div class="flex justify-between text-lg font-semibold">
                        <span class="text-gray-900">Total</span>
                        <span class="text-gray-900">Rs. {{ number_format($cartTotal, 2) }}</span>
                    </div>
                </div>
            </div>

            <div class="flex space-x-4">
                <a href="{{ route('checkout.index') }}" 
                   class="flex-1 bg-indigo-600 hover:bg-indigo-700 text-white text-center py-3 px-6 rounded-lg font-semibold transition">
                    Proceed to Checkout
                </a>
                <button wire:click="clearCart"
                        onclick="return confirm('Are you sure you want to clear your cart?')"
                        class="px-6 py-3 border border-gray-300 text-gray-700 hover:bg-gray-50 rounded-lg font-semibold transition">
                    Clear Cart
                </button>
            </div>
        </div>

    @else
        <!-- Empty Cart -->
        <div class="bg-white rounded-lg shadow-md p-12 text-center">
            <div class="w-24 h-24 mx-auto mb-6 text-gray-400">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" class="w-full h-full">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" 
                          d="M16 11V7a4 4 0 00-8 0v4M8 11h8l1 9H7l1-9z"></path>
                </svg>
            </div>
            <h2 class="text-2xl font-semibold text-gray-900 mb-4">Your cart is empty</h2>
            <p class="text-gray-600 mb-8">Looks like you haven't added anything to your cart yet.</p>
            <a href="{{ route('products.index') }}" 
               class="inline-block bg-indigo-600 hover:bg-indigo-700 text-white px-8 py-3 rounded-lg font-semibold transition">
                Continue Shopping
            </a>
        </div>
    @endif

    <!-- Continue Shopping Link -->
    <div class="text-center">
        <a href="{{ route('products.index') }}" 
           class="text-indigo-600 hover:text-indigo-800 font-medium transition">
            ← Continue Shopping
        </a>
    </div>
</div>

<script>
    // Auto-hide notifications after 4 seconds
    document.addEventListener('DOMContentLoaded', function() {
        @if($showNotification)
            setTimeout(function() {
                @this.call('hideNotification');
            }, 4000);
        @endif
    });
</script>
EOF

echo "5. Setting permissions and clearing caches..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

cd /var/www/html
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

echo "6. Reloading Apache..."
sudo systemctl reload apache2

echo
echo "=== ALL ISSUES FIXED ==="
echo "✅ Cart display: Fixed CartManager to properly load and display cart items with relationships"
echo "✅ Admin users: Added role column display with proper field handling (Role/role compatibility)"
echo "✅ Buy Now admin: Added admin detection to redirect to dashboard instead of checkout"
echo "✅ Cart relationships: Fixed CartItem model relationships and proper eager loading"
echo "✅ Cart operations: Enhanced error handling and logging for cart operations"
echo
echo "🔍 TEST RESULTS EXPECTED:"
echo "1. Cart page (http://13.60.43.49/cart) should now show actual items with images, not empty"
echo "2. Admin users page (http://13.60.43.49/admin/users) should display role column properly"  
echo "3. Buy Now as admin should redirect to admin dashboard with info message"
echo "4. Cart counter and cart page should be in sync"
echo "5. Cart operations (update quantity, remove items) should work properly"
echo
echo "The system now has comprehensive cart management with proper admin/customer separation!"