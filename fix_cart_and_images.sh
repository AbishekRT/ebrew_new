#!/bin/bash

echo "=== eBrew Cart Counter & Image Display Fix ==="
echo "Timestamp: $(date)"
echo

# Backup current files
echo "1. Creating backups..."
sudo cp /var/www/html/app/Livewire/AddToCart.php /var/www/html/app/Livewire/AddToCart.php.backup
sudo cp /var/www/html/app/Livewire/CartCounter.php /var/www/html/app/Livewire/CartCounter.php.backup
sudo cp /var/www/html/resources/views/livewire/cart-counter.blade.php /var/www/html/resources/views/livewire/cart-counter.blade.php.backup
sudo cp /var/www/html/resources/views/livewire/add-to-cart.blade.php /var/www/html/resources/views/livewire/add-to-cart.blade.php.backup
sudo cp /var/www/html/resources/views/admin/products/index.blade.php /var/www/html/resources/views/admin/products/index.blade.php.backup

echo "2. Updating AddToCart.php (Enhanced event dispatching)..."
sudo tee /var/www/html/app/Livewire/AddToCart.php > /dev/null << 'EOF'
<?php

namespace App\Livewire;

use Livewire\Component;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Item;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class AddToCart extends Component
{
    public $item;
    public $itemId;
    public $quantity = 1;
    public $showNotification = false;
    public $notificationMessage = '';
    public $notificationType = 'success';
    public $isAdding = false;
    public $debugMessage = 'Component loaded!';

    public function mount($itemId)
    {
        $this->itemId = $itemId;
        $this->item = Item::findOrFail($itemId);
        $this->debugMessage = 'Item loaded: ' . $this->item->Name;
    }

    public function incrementQuantity()
    {
        $this->quantity++;
    }

    public function decrementQuantity()
    {
        if ($this->quantity > 1) {
            $this->quantity--;
        }
    }

    public function addToCart()
    {
        Log::info('AddToCart: Method called', [
            'item_id' => $this->item->id,
            'item_name' => $this->item->Name,
            'quantity' => $this->quantity,
            'is_auth' => Auth::check()
        ]);

        // Check if user is authenticated - require login for cart
        if (!Auth::check()) {
            $this->showNotification('Please login to add items to cart.', 'error');
            return redirect()->route('login');
        }

        $this->isAdding = true;

        try {
            // Validate item exists and has required fields
            if (!$this->item || !$this->item->id || !$this->item->Name || $this->item->Price === null) {
                throw new \Exception('Invalid item data: Item ID=' . ($this->item->id ?? 'null') . ', Name=' . ($this->item->Name ?? 'null') . ', Price=' . ($this->item->Price ?? 'null'));
            }
            
            // Validate quantity
            if ($this->quantity < 1) {
                throw new \Exception('Invalid quantity: must be at least 1');
            }

            // Authenticated user - save to database
            Log::info('AddToCart: Authenticated user cart', ['user_id' => Auth::id()]);
            
            // Ensure user exists and is valid
            $user = Auth::user();
            if (!$user || !$user->id) {
                throw new \Exception('Invalid user authentication state');
            }
            
            $cart = Cart::firstOrCreate(['UserID' => Auth::id()]);
            
            // Validate cart was created/found successfully
            if (!$cart || !$cart->id) {
                throw new \Exception('Failed to create or find user cart');
            }
            
            Log::info('AddToCart: Cart created/found', ['cart_id' => $cart->id, 'user_id' => Auth::id()]);
            
            // Check if item already exists in cart
            $existingCartItem = CartItem::where('CartID', $cart->id)
                ->where('ItemID', $this->item->id)  // Use standard id field
                ->first();

            if ($existingCartItem) {
                Log::info('AddToCart: Updating existing item', [
                    'cart_item_id' => $existingCartItem->id,
                    'current_quantity' => $existingCartItem->Quantity,
                    'adding_quantity' => $this->quantity
                ]);
                
                // Update existing cart item quantity
                $newQuantity = $existingCartItem->Quantity + $this->quantity;
                $updated = CartItem::where('CartID', $cart->id)
                       ->where('ItemID', $this->item->id)
                       ->update(['Quantity' => $newQuantity]);
                       
                if (!$updated) {
                    throw new \Exception('Failed to update cart item quantity');
                }
            } else {
                Log::info('AddToCart: Creating new cart item', [
                    'cart_id' => $cart->id,
                    'item_id' => $this->item->id,
                    'quantity' => $this->quantity
                ]);
                
                // Validate required data before creation
                if (!$cart->id || !$this->item->id || !$this->quantity) {
                    throw new \Exception('Invalid data for cart item creation: CartID=' . ($cart->id ?? 'null') . ', ItemID=' . ($this->item->id ?? 'null') . ', Quantity=' . ($this->quantity ?? 'null'));
                }
                
                // Create new cart item with explicit validation
                $cartItemData = [
                    'CartID' => (int) $cart->id,
                    'ItemID' => (int) $this->item->id,  // Use standard id field
                    'Quantity' => (int) $this->quantity
                ];
                
                Log::info('AddToCart: Attempting to create cart item', $cartItemData);
                
                $cartItem = CartItem::create($cartItemData);
                
                if (!$cartItem || !$cartItem->id) {
                    throw new \Exception('CartItem creation failed - no item returned or no ID assigned');
                }
                
                Log::info('AddToCart: Cart item created successfully', [
                    'cart_item_id' => $cartItem->id,
                    'cart_id' => $cartItem->CartID,
                    'item_id' => $cartItem->ItemID,
                    'quantity' => $cartItem->Quantity
                ]);
            }

            Log::info('AddToCart: Success - dispatching cartUpdated event');
            // Dispatch to all components and specifically target cart-counter
            $this->dispatch('cartUpdated');
            $this->dispatch('cartUpdated')->to('cart-counter');
            $this->showNotification("{$this->item->Name} added to cart successfully!", 'success');
            
            // Reset quantity to 1 after adding
            $this->quantity = 1;

        } catch (\Exception $e) {
            Log::error('AddToCart: Critical error occurred', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'item_id' => $this->item->id ?? 'unknown',
                'user_id' => Auth::id(),
                'trace' => $e->getTraceAsString()
            ]);
            $this->showNotification($e->getMessage(), 'error');
        }

        $this->isAdding = false;
    }

    private function showNotification($message, $type = 'success')
    {
        $this->notificationMessage = $message;
        $this->notificationType = $type;
        $this->showNotification = true;
    }

    public function hideNotification()
    {
        $this->showNotification = false;
        $this->notificationMessage = '';
        $this->notificationType = 'success';
    }

    public function render()
    {
        return view('livewire.add-to-cart');
    }
}
EOF

echo "3. Updating CartCounter.php (Enhanced event listening)..."
sudo tee /var/www/html/app/Livewire/CartCounter.php > /dev/null << 'EOF'
<?php

namespace App\Livewire;

use Livewire\Component;
use App\Models\Cart;
use App\Models\CartItem;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class CartCounter extends Component
{
    public $cartCount = 0;

    protected $listeners = [
        'cartUpdated' => 'updateCount',
        'cartChanged' => 'updateCount',
        'itemAddedToCart' => 'updateCount'
    ];

    public function mount()
    {
        $this->updateCount();
    }

    public function updateCount()
    {
        try {
            // Only log in development/local environments
            if (app()->environment(['local', 'development'])) {
                Log::info('CartCounter: Updating count', ['is_auth' => Auth::check()]);
            }
            
            if (Auth::check()) {
                // Authenticated user - get from database with error handling
                try {
                    $cart = Cart::where('UserID', Auth::id())->first();
                    
                    if ($cart) {
                        $this->cartCount = CartItem::where('CartID', $cart->id)->sum('Quantity') ?? 0;
                    } else {
                        $this->cartCount = 0;
                    }
                } catch (\Exception $e) {
                    // Fallback to session if database fails
                    if (app()->environment(['local', 'development'])) {
                        Log::error('CartCounter: Database error, falling back to session', ['error' => $e->getMessage()]);
                    }
                    $sessionCart = session()->get('cart', []);
                    $this->cartCount = collect($sessionCart)->sum('quantity') ?? 0;
                }
            } else {
                // Guest user - get from session
                $sessionCart = session()->get('cart', []);
                $this->cartCount = collect($sessionCart)->sum('quantity') ?? 0;
                
                if (app()->environment(['local', 'development'])) {
                    Log::info('CartCounter: Guest cart count', [
                        'session_cart' => $sessionCart,
                        'count' => $this->cartCount
                    ]);
                }
            }
            
            if (app()->environment(['local', 'development'])) {
                Log::info('CartCounter: Final count', ['count' => $this->cartCount]);
            }
        } catch (\Exception $e) {
            // Ultimate fallback - set count to 0
            if (app()->environment(['local', 'development', 'staging'])) {
                Log::error('CartCounter: Critical error, setting count to 0', ['error' => $e->getMessage()]);
            }
            $this->cartCount = 0;
        }
    }

    public function forceUpdate()
    {
        $this->updateCount();
    }

    public function render()
    {
        return view('livewire.cart-counter');
    }
}
EOF

echo "4. Updating cart-counter.blade.php (Enhanced with polling and JS events)..."
sudo tee /var/www/html/resources/views/livewire/cart-counter.blade.php > /dev/null << 'EOF'
<div wire:poll.5s="updateCount">
    <a href="{{ route('cart.index') }}" 
       class="hover:text-yellow-900 transition {{ request()->routeIs('cart.index') ? 'text-yellow-900 font-bold border-b-2 border-yellow-900' : '' }} relative inline-flex items-center" 
       onclick="return handleCartClick(event)">
        <!-- Shopping Cart Icon -->
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M8 11h8l1 9H7l1-9z"></path>
            <circle cx="9" cy="20" r="1"></circle>
            <circle cx="20" cy="20" r="1"></circle>
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M1 1h4l2.68 13.39a2 2 0 002 1.61h9.72"></path>
        </svg>
        @if($cartCount > 0)
            <span class="absolute -top-2 -right-2 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center animate-pulse">
                {{ $cartCount > 99 ? '99+' : $cartCount }}
            </span>
        @endif
    </a>
</div>

<script>
    // Listen for custom cart events
    window.addEventListener('cartUpdated', function() {
        @this.call('forceUpdate');
    });
    
    // Also listen for Livewire events
    Livewire.on('cartUpdated', () => {
        @this.call('forceUpdate');
    });
</script>
EOF

echo "5. Updating add-to-cart.blade.php (Enhanced with JS event dispatch)..."
sudo tee /var/www/html/resources/views/livewire/add-to-cart.blade.php > /dev/null << 'EOF'
<div class="space-y-4">
    <!-- Notification -->
    @if($showNotification)
        <div class="fixed top-20 right-4 z-40 {{ $notificationType === 'error' ? 'bg-red-500' : 'bg-green-500' }} text-white px-6 py-4 rounded-lg shadow-lg max-w-sm"
             id="cart-notification-{{ $itemId }}"
             style="animation: slideInRight 0.3s ease-out;">
            <div class="flex items-center space-x-2">
                @if($notificationType === 'error')
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                @else
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                    </svg>
                @endif
                <span class="flex-1">{{ $notificationMessage }}</span>
                <button class="ml-2 text-white hover:text-gray-200 flex-shrink-0" 
                        wire:click="hideNotification">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                    </svg>
                </button>
            </div>
        </div>
        
        <style>
            @keyframes slideInRight {
                from {
                    transform: translateX(100%);
                    opacity: 0;
                }
                to {
                    transform: translateX(0);
                    opacity: 1;
                }
            }
            
            @keyframes slideOutRight {
                from {
                    transform: translateX(0);
                    opacity: 1;
                }
                to {
                    transform: translateX(100%);
                    opacity: 0;
                }
            }
            
            .notification-hide {
                animation: slideOutRight 0.3s ease-in forwards;
            }
        </style>
        
        <script>
            // Auto-hide notification after 4 seconds
            setTimeout(function() {
                Livewire.find('{{ $_instance->getId() }}').call('hideNotification');
            }, 4000);
            
            // Dispatch custom JavaScript event for cart updates
            window.dispatchEvent(new CustomEvent('cartUpdated', {
                detail: { itemId: {{ $itemId }}, itemName: '{{ $item->Name }}' }
            }));
        </script>
    @endif

    <!-- Quantity Selector and Add to Cart Button -->
    <div class="flex items-center space-x-4">
        <!-- Quantity Selector -->
        <div class="flex items-center border border-gray-300 rounded-lg">
            <button type="button" 
                    wire:click="decrementQuantity"
                    class="px-3 py-2 text-xl font-bold text-gray-800 hover:bg-gray-100 rounded-l-lg transition">
                −
            </button>
            <div class="w-16 text-center text-lg font-semibold border-l border-r border-gray-300 py-2">
                {{ $quantity }}
            </div>
            <button type="button" 
                    wire:click="incrementQuantity"
                    class="px-3 py-2 text-xl font-bold text-gray-800 hover:bg-gray-100 rounded-r-lg transition">
                +
            </button>
        </div>

        <!-- Add to Cart Button -->
        <button type="button" 
                wire:click="addToCart"
                class="bg-[#cc0000] hover:bg-[#a30000] text-white font-semibold px-6 py-2 rounded-lg transition">
            <i class="fas fa-cart-plus mr-2"></i>Add to Cart
        </button>
        
        <!-- Buy Now Button -->
        <a href="{{ route('checkout.buy-now', ['itemId' => $item->id]) }}" 
           class="bg-yellow-600 hover:bg-yellow-700 text-white font-semibold px-6 py-2 rounded-lg transition">
            <i class="fas fa-bolt mr-2"></i>Buy Now
        </a>
    </div>

    <!-- Product Info Summary (Optional) -->
    <div class="text-sm text-gray-600">
        <p>Rs. {{ number_format($item->Price, 2) }} each</p>
        @if($quantity > 1)
            <p class="text-gray-700 font-semibold">Total: Rs. {{ number_format($item->Price * $quantity, 2) }}</p>
        @endif
    </div>
</div>
EOF

echo "6. Updating admin products index.blade.php (Fix image display)..."
sudo tee /var/www/html/resources/views/admin/products/index.blade.php > /dev/null << 'EOF'
@extends('layouts.app')

@section('content')
<div class="min-h-screen bg-gray-50 py-6">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <!-- Header -->
        <div class="bg-white shadow rounded-lg mb-6 p-6">
            <div class="flex justify-between items-center">
                <h1 class="text-3xl font-bold text-gray-900">Manage Products</h1>
                <a href="{{ route('admin.dashboard') }}" class="bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded-lg transition duration-200">
                    Back to Dashboard
                </a>
            </div>
        </div>

        @if(session('success'))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
                {{ session('success') }}
            </div>
        @endif

        @if ($errors->any())
            <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
                <ul class="list-disc list-inside">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <!-- Add Product Form -->
        <div class="bg-white shadow rounded-lg mb-8 p-6">
            <h2 class="text-xl font-semibold text-gray-900 mb-4">Add New Product</h2>
            <form action="{{ route('admin.products.store') }}" method="POST" enctype="multipart/form-data" class="grid grid-cols-1 md:grid-cols-2 gap-6">
                @csrf
                
                <div class="space-y-4">
                    <div>
                        <label for="name" class="block text-sm font-medium text-gray-700">Product Name</label>
                        <input type="text" id="name" name="name" value="{{ old('name') }}" required
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                    </div>

                    <div>
                        <label for="price" class="block text-sm font-medium text-gray-700">Price ($)</label>
                        <input type="number" id="price" name="price" value="{{ old('price') }}" step="0.01" min="0" required
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                    </div>

                    <div>
                        <label for="roast_date" class="block text-sm font-medium text-gray-700">Roast Date</label>
                        <input type="date" id="roast_date" name="roast_date" value="{{ old('roast_date') }}"
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                    </div>

                    <div>
                        <label for="image" class="block text-sm font-medium text-gray-700">Product Image</label>
                        <input type="file" id="image" name="image" accept="image/*"
                               class="mt-1 block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100">
                    </div>
                </div>

                <div class="space-y-4">
                    <div>
                        <label for="description" class="block text-sm font-medium text-gray-700">Description</label>
                        <textarea id="description" name="description" rows="3" required
                                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">{{ old('description') }}</textarea>
                    </div>

                    <div>
                        <label for="tasting_notes" class="block text-sm font-medium text-gray-700">Tasting Notes</label>
                        <textarea id="tasting_notes" name="tasting_notes" rows="3"
                                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">{{ old('tasting_notes') }}</textarea>
                    </div>

                    <div>
                        <label for="shipping_returns" class="block text-sm font-medium text-gray-700">Shipping & Returns</label>
                        <textarea id="shipping_returns" name="shipping_returns" rows="3"
                                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">{{ old('shipping_returns') }}</textarea>
                    </div>

                    <div class="flex justify-end">
                        <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2 rounded-lg transition duration-200">
                            Add Product
                        </button>
                    </div>
                </div>
            </form>
        </div>

        <!-- Products List -->
        <div class="bg-white shadow rounded-lg">
            <div class="px-6 py-4 border-b border-gray-200">
                <h2 class="text-xl font-semibold text-gray-900">Existing Products ({{ $products->count() }})</h2>
            </div>
            
            @if($products->count() > 0)
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Image</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Price</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Description</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Roast Date</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            @foreach($products as $product)
                                <tr>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        @if($product->Image)
                                            <img src="{{ $product->image_url }}" alt="{{ $product->Name }}" class="h-16 w-16 object-cover rounded">
                                        @else
                                            <div class="h-16 w-16 bg-gray-200 rounded flex items-center justify-center">
                                                <span class="text-gray-400 text-xs">No Image</span>
                                            </div>
                                        @endif
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm font-medium text-gray-900">{{ $product->Name }}</div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm text-gray-900">${{ number_format($product->Price, 2) }}</div>
                                    </td>
                                    <td class="px-6 py-4">
                                        <div class="text-sm text-gray-900 max-w-xs truncate">{{ $product->Description }}</div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm text-gray-900">
                                            {{ $product->RoastDates ? \Carbon\Carbon::parse($product->RoastDates)->format('M d, Y') : 'N/A' }}
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                        <div class="flex space-x-2">
                                            <a href="{{ route('admin.products.edit', $product->id) }}" 
                                               class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded text-xs transition duration-200">
                                                Edit
                                            </a>
                                            <form action="{{ route('admin.products.destroy', $product->id) }}" method="POST" 
                                                  onsubmit="return confirm('Are you sure you want to delete this product?')" class="inline">
                                                @csrf
                                                @method('DELETE')
                                                <button type="submit" 
                                                        class="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-xs transition duration-200">
                                                    Delete
                                                </button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @else
                <div class="px-6 py-12 text-center">
                    <div class="text-gray-500 text-lg">No products found</div>
                    <div class="text-gray-400 text-sm mt-2">Add your first product using the form above</div>
                </div>
            @endif
        </div>
    </div>
</div>

@push('scripts')
<script>
    // Ensure Livewire is loaded and events work properly
    document.addEventListener('DOMContentLoaded', function() {
        console.log('Admin products page loaded with Livewire support');
    });
</script>
@endpush

@endsection
EOF

echo "7. Setting proper permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

echo "8. Clearing Laravel caches..."
cd /var/www/html
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear
php artisan livewire:discover

echo "9. Reloading Apache..."
sudo systemctl reload apache2

echo
echo "=== FIXES APPLIED ==="
echo "✅ Cart counter events: Enhanced with multiple listeners and JavaScript fallbacks"
echo "✅ Product images: Fixed to use image_url accessor instead of raw Image field"
echo "✅ Event dispatching: Added specific targeting for cart-counter component"
echo "✅ Polling fallback: Cart counter now polls every 5 seconds as backup"
echo "✅ JavaScript events: Added custom window events as additional fallback"
echo 
echo "🔍 TEST NOW:"
echo "1. Go to http://13.60.43.49/products/2"
echo "2. Login as a customer"
echo "3. Click 'Add to Cart' - you should see:"
echo "   - Success message appearing"
echo "   - Cart counter in header updating with red badge"
echo "4. Go to http://13.60.43.49/admin/products"
echo "5. Login as admin (abhishake.a@gmail.com / asiri12345)"
echo "6. Check if product images are now visible in the table"
echo
echo "If cart counter still doesn't work immediately, wait 5 seconds for the polling to kick in."
echo "The cart system now has multiple fallback mechanisms for maximum reliability!"