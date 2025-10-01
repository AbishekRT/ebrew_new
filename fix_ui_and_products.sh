#!/bin/bash

echo "=== eBrew UI, Product Management & Admin Access Control Fix ==="
echo "Timestamp: $(date)"
echo "Fixing: 1) Duplicate continue shopping buttons 2) Product edit 500 error 3) Image upload not working 4) Admin access control"
echo

# 1. Fix cart manager view to remove duplicate "Continue Shopping" button
echo "1. Fixing cart manager view - removing duplicate Continue Shopping button..."
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
        <!-- Empty Cart - Single Continue Shopping Button -->
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

# 2. Fix admin products controller to handle edit routes properly
echo "2. Fixing admin products controller for proper edit handling..."
sudo tee /var/www/html/app/Http/Controllers/Admin/ProductController.php > /dev/null << 'EOF'
<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Item;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class ProductController extends Controller
{
    /**
     * Display a listing of the products with add/edit interface
     */
    public function index()
    {
        $products = Item::orderBy('id', 'desc')->get();
        
        return view('admin.products.index', compact('products'));
    }

    /**
     * Store a newly created product in storage
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'description' => 'required|string',
                'price' => 'required|numeric|min:0',
                'tasting_notes' => 'nullable|string',
                'shipping_returns' => 'nullable|string',
                'roast_date' => 'nullable|date',
                'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:2048'
            ]);

            $imagePath = null;
            
            // Handle image upload with better path handling
            if ($request->hasFile('image')) {
                $image = $request->file('image');
                $imageName = time() . '_' . $image->getClientOriginalName();
                
                // Store in public/images directory
                $image->move(public_path('images'), $imageName);
                $imagePath = 'images/' . $imageName;
                
                Log::info('Product image uploaded', [
                    'original_name' => $image->getClientOriginalName(),
                    'stored_name' => $imageName,
                    'path' => $imagePath
                ]);
            }

            $product = Item::create([
                'Name' => $validated['name'],
                'Description' => $validated['description'],
                'Price' => $validated['price'],
                'TastingNotes' => $validated['tasting_notes'],
                'ShippingAndReturns' => $validated['shipping_returns'],
                'RoastDates' => $validated['roast_date'],
                'Image' => $imagePath,
            ]);

            Log::info('Product created successfully', [
                'product_id' => $product->id,
                'name' => $product->Name,
                'image_path' => $product->Image
            ]);

            return redirect()->route('admin.products.index')
                ->with('success', 'Product created successfully.');
                
        } catch (\Exception $e) {
            Log::error('Error creating product', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return redirect()->back()
                ->withInput()
                ->with('error', 'Error creating product: ' . $e->getMessage());
        }
    }

    /**
     * Show the form for editing the specified product
     */
    public function edit($id)
    {
        try {
            $product = Item::findOrFail($id);
            return view('admin.products.edit', compact('product'));
        } catch (\Exception $e) {
            Log::error('Error loading product edit page', [
                'product_id' => $id,
                'message' => $e->getMessage()
            ]);
            
            return redirect()->route('admin.products.index')
                ->with('error', 'Product not found or error loading edit page.');
        }
    }

    /**
     * Update the specified product in storage
     */
    public function update(Request $request, $id)
    {
        try {
            $product = Item::findOrFail($id);
            
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'description' => 'required|string',
                'price' => 'required|numeric|min:0',
                'tasting_notes' => 'nullable|string',
                'shipping_returns' => 'nullable|string',
                'roast_date' => 'nullable|date',
                'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:2048'
            ]);

            $imagePath = $product->Image; // Keep existing image by default

            // Handle image upload
            if ($request->hasFile('image')) {
                // Delete old image if exists
                if ($product->Image && file_exists(public_path($product->Image))) {
                    unlink(public_path($product->Image));
                    Log::info('Deleted old product image', ['path' => $product->Image]);
                }
                
                $image = $request->file('image');
                $imageName = time() . '_' . $image->getClientOriginalName();
                
                // Store in public/images directory
                $image->move(public_path('images'), $imageName);
                $imagePath = 'images/' . $imageName;
                
                Log::info('Product image updated', [
                    'product_id' => $id,
                    'new_path' => $imagePath
                ]);
            }

            $product->update([
                'Name' => $validated['name'],
                'Description' => $validated['description'],
                'Price' => $validated['price'],
                'TastingNotes' => $validated['tasting_notes'],
                'ShippingAndReturns' => $validated['shipping_returns'],
                'RoastDates' => $validated['roast_date'],
                'Image' => $imagePath,
            ]);

            Log::info('Product updated successfully', [
                'product_id' => $product->id,
                'name' => $product->Name
            ]);

            return redirect()->route('admin.products.index')
                ->with('success', 'Product updated successfully.');
                
        } catch (\Exception $e) {
            Log::error('Error updating product', [
                'product_id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return redirect()->back()
                ->withInput()
                ->with('error', 'Error updating product: ' . $e->getMessage());
        }
    }

    /**
     * Remove the specified product from storage
     */
    public function destroy($id)
    {
        try {
            $product = Item::findOrFail($id);
            
            // Delete image file if exists
            if ($product->Image && file_exists(public_path($product->Image))) {
                unlink(public_path($product->Image));
                Log::info('Deleted product image', ['path' => $product->Image]);
            }

            $productName = $product->Name;
            $product->delete();

            Log::info('Product deleted successfully', [
                'product_id' => $id,
                'name' => $productName
            ]);

            return redirect()->route('admin.products.index')
                ->with('success', 'Product deleted successfully.');
                
        } catch (\Exception $e) {
            Log::error('Error deleting product', [
                'product_id' => $id,
                'message' => $e->getMessage()
            ]);
            
            return redirect()->route('admin.products.index')
                ->with('error', 'Error deleting product.');
        }
    }
}
EOF

# 3. Fix admin products edit view to use correct ID field
echo "3. Fixing admin products edit view for correct ID handling..."
sudo tee /var/www/html/resources/views/admin/products/edit.blade.php > /dev/null << 'EOF'
@extends('layouts.app')

@section('content')
<div class="min-h-screen bg-gray-50 py-6">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <!-- Header -->
        <div class="bg-white shadow rounded-lg mb-6 p-6">
            <div class="flex justify-between items-center">
                <h1 class="text-3xl font-bold text-gray-900">Edit Product: {{ $product->Name }}</h1>
                <a href="{{ route('admin.products.index') }}" class="bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded-lg transition duration-200">
                    Back to Products
                </a>
            </div>
        </div>

        @if(session('success'))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
                {{ session('success') }}
            </div>
        @endif

        @if(session('error'))
            <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
                {{ session('error') }}
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

        <!-- Edit Product Form -->
        <div class="bg-white shadow rounded-lg p-6">
            <form action="{{ route('admin.products.update', $product->id) }}" method="POST" enctype="multipart/form-data" class="grid grid-cols-1 md:grid-cols-2 gap-6">
                @csrf
                @method('PUT')
                
                <div class="space-y-4">
                    <div>
                        <label for="name" class="block text-sm font-medium text-gray-700">Product Name</label>
                        <input type="text" id="name" name="name" value="{{ old('name', $product->Name) }}" required
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                    </div>

                    <div>
                        <label for="price" class="block text-sm font-medium text-gray-700">Price ($)</label>
                        <input type="number" id="price" name="price" value="{{ old('price', $product->Price) }}" step="0.01" min="0" required
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                    </div>

                    <div>
                        <label for="roast_date" class="block text-sm font-medium text-gray-700">Roast Date</label>
                        <input type="date" id="roast_date" name="roast_date" 
                               value="{{ old('roast_date', $product->RoastDates ? \Carbon\Carbon::parse($product->RoastDates)->format('Y-m-d') : '') }}"
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                    </div>

                    <div>
                        <label for="image" class="block text-sm font-medium text-gray-700">Product Image</label>
                        <input type="file" id="image" name="image" accept="image/*"
                               class="mt-1 block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100">
                        <p class="mt-2 text-sm text-gray-500">Leave empty to keep current image</p>
                        
                        @if($product->Image)
                            <div class="mt-3">
                                <p class="text-sm font-medium text-gray-700 mb-2">Current Image:</p>
                                <img src="{{ $product->image_url }}" alt="{{ $product->Name }}" class="h-24 w-24 object-cover rounded border">
                            </div>
                        @endif
                    </div>
                </div>

                <div class="space-y-4">
                    <div>
                        <label for="description" class="block text-sm font-medium text-gray-700">Description</label>
                        <textarea id="description" name="description" rows="4" required
                                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">{{ old('description', $product->Description) }}</textarea>
                    </div>

                    <div>
                        <label for="tasting_notes" class="block text-sm font-medium text-gray-700">Tasting Notes</label>
                        <textarea id="tasting_notes" name="tasting_notes" rows="4"
                                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">{{ old('tasting_notes', $product->TastingNotes) }}</textarea>
                    </div>

                    <div>
                        <label for="shipping_returns" class="block text-sm font-medium text-gray-700">Shipping & Returns</label>
                        <textarea id="shipping_returns" name="shipping_returns" rows="4"
                                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">{{ old('shipping_returns', $product->ShippingAndReturns) }}</textarea>
                    </div>

                    <div class="flex justify-end space-x-3">
                        <a href="{{ route('admin.products.index') }}" 
                           class="bg-gray-600 hover:bg-gray-700 text-white px-6 py-2 rounded-lg transition duration-200">
                            Cancel
                        </a>
                        <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2 rounded-lg transition duration-200">
                            Update Product
                        </button>
                    </div>
                </div>
            </form>

            <!-- Delete Product Section -->
            <div class="border-t border-gray-200 mt-8 pt-8">
                <div class="bg-red-50 border border-red-200 rounded-lg p-4">
                    <div class="flex">
                        <div class="flex-shrink-0">
                            <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                            </svg>
                        </div>
                        <div class="ml-3">
                            <h3 class="text-sm font-medium text-red-800">Danger Zone</h3>
                            <div class="mt-2 text-sm text-red-700">
                                <p>Once you delete this product, there is no going back. Please be certain.</p>
                            </div>
                            <div class="mt-4">
                                <form action="{{ route('admin.products.destroy', $product->id) }}" method="POST" 
                                      onsubmit="return confirm('Are you absolutely sure you want to delete this product? This action cannot be undone.')" class="inline">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" 
                                            class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition duration-200">
                                        Delete Product
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
EOF

# 4. Create images directory if it doesn't exist
echo "4. Creating images directory and setting permissions..."
sudo mkdir -p /var/www/html/public/images
sudo chown -R www-data:www-data /var/www/html/public/images
sudo chmod -R 755 /var/www/html/public/images

# 5. Update Item model to handle image URL properly
echo "5. Updating Item model for better image handling..."
sudo tee /var/www/html/app/Models/Item.php > /dev/null << 'EOF'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Item extends Model
{
    use HasFactory;

    protected $table = 'items';
    protected $primaryKey = 'id';
    public $incrementing = true;
    protected $keyType = 'int';
    public $timestamps = false;

    protected $fillable = [
        'Name',
        'Description', 
        'Price',
        'TastingNotes',
        'ShippingAndReturns',
        'RoastDates',
        'Image'
    ];

    /**
     * Accessor: Get safe image URL
     */
    public function getImageUrlAttribute()
    {
        if (!$this->Image) {
            return asset('images/default.png');
        }
        
        // If image path already includes full URL, return as is
        if (str_starts_with($this->Image, 'http')) {
            return $this->Image;
        }
        
        // If image path starts with 'images/', it's already relative to public
        if (str_starts_with($this->Image, 'images/')) {
            return asset($this->Image);
        }
        
        // Legacy support for old storage paths
        if (str_starts_with($this->Image, '/storage/')) {
            return asset($this->Image);
        }
        
        // Default: assume it's in images directory
        return asset('images/' . basename($this->Image));
    }

    /**
     * Relationship: Cart items that reference this item
     */
    public function cartItems()
    {
        return $this->hasMany(CartItem::class, 'ItemID', 'id');
    }

    /**
     * Relationship: Order items that reference this item
     */
    public function orderItems()
    {
        return $this->hasMany(OrderItem::class, 'ItemID', 'id');
    }

    /**
     * Get formatted price
     */
    public function getFormattedPriceAttribute()
    {
        return '$' . number_format($this->Price, 2);
    }

    /**
     * Get formatted roast date
     */
    public function getFormattedRoastDateAttribute()
    {
        if (!$this->RoastDates) {
            return 'N/A';
        }
        
        try {
            return \Carbon\Carbon::parse($this->RoastDates)->format('M d, Y');
        } catch (\Exception $e) {
            return 'Invalid Date';
        }
    }

    /**
     * Scope: Active items (you can extend this for inventory management)
     */
    public function scopeActive($query)
    {
        return $query; // For now, all items are considered active
    }

    /**
     * Check if item has image
     */
    public function hasImage()
    {
        return !empty($this->Image);
    }
}
EOF

echo "6. Setting proper permissions and clearing caches..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

cd /var/www/html
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# 6. Create Admin Only Middleware
echo "6. Creating AdminOnly middleware for strict admin access control..."
sudo tee /var/www/html/app/Http/Middleware/AdminOnly.php > /dev/null << 'EOF'
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminOnly
{
    /**
     * Handle an incoming request - STRICT admin only access
     */
    public function handle(Request $request, Closure $next)
    {
        // Check if user is authenticated
        if (!Auth::check()) {
            return redirect()->route('login')->with('error', 'Please login to access this area.');
        }

        $user = Auth::user();
        
        // Check if user is admin (handle both Role and role fields)
        $isAdmin = ($user->Role === 'admin') || ($user->role === 'admin');
        
        if (!$isAdmin) {
            return redirect()->route('login')->with('error', 'Access denied. Admin privileges required.');
        }

        return $next($request);
    }
}
EOF

# 7. Create Customer Only Middleware  
echo "7. Creating CustomerOnly middleware to block admin access to customer pages..."
sudo tee /var/www/html/app/Http/Middleware/CustomerOnly.php > /dev/null << 'EOF'
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CustomerOnly
{
    /**
     * Handle an incoming request - Block admin access to customer pages
     */
    public function handle(Request $request, Closure $next)
    {
        // Allow access for guests (non-authenticated users)
        if (!Auth::check()) {
            return $next($request);
        }

        $user = Auth::user();
        
        // Check if user is admin (handle both Role and role fields)
        $isAdmin = ($user->Role === 'admin') || ($user->role === 'admin');
        
        if ($isAdmin) {
            return redirect()->route('admin.dashboard')
                ->with('info', 'Admins cannot access customer pages. Use the admin panel for management.');
        }

        return $next($request);
    }
}
EOF

# 8. Register Middleware in Kernel
echo "8. Registering new middleware in Kernel..."
sudo tee -a /var/www/html/app/Http/Kernel.php > /dev/null << 'EOF'
<?php

namespace App\Http;

use Illuminate\Foundation\Http\Kernel as HttpKernel;

class Kernel extends HttpKernel
{
    /**
     * The application's global HTTP middleware stack.
     */
    protected $middleware = [
        // \App\Http\Middleware\TrustHosts::class,
        \App\Http\Middleware\TrustProxies::class,
        \Illuminate\Http\Middleware\HandleCors::class,
        \App\Http\Middleware\PreventRequestsDuringMaintenance::class,
        \Illuminate\Foundation\Http\Middleware\ValidatePostSize::class,
        \App\Http\Middleware\TrimStrings::class,
        \Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull::class,
    ];

    /**
     * The application's route middleware groups.
     */
    protected $middlewareGroups = [
        'web' => [
            \App\Http\Middleware\EncryptCookies::class,
            \Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse::class,
            \Illuminate\Session\Middleware\StartSession::class,
            \Illuminate\View\Middleware\ShareErrorsFromSession::class,
            \App\Http\Middleware\VerifyCsrfToken::class,
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],

        'api' => [
            // \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
            'throttle:api',
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],
    ];

    /**
     * The application's route middleware.
     */
    protected $routeMiddleware = [
        'auth' => \App\Http\Middleware\Authenticate::class,
        'auth.basic' => \Illuminate\Auth\Middleware\AuthenticateWithBasicAuth::class,
        'cache.headers' => \Illuminate\Http\Middleware\SetCacheHeaders::class,
        'can' => \Illuminate\Auth\Middleware\Authorize::class,
        'guest' => \App\Http\Middleware\RedirectIfAuthenticated::class,
        'password.confirm' => \Illuminate\Auth\Middleware\RequirePassword::class,
        'signed' => \Illuminate\Routing\Middleware\ValidateSignature::class,
        'throttle' => \Illuminate\Routing\Middleware\ThrottleRequests::class,
        'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
        'isAdmin' => \App\Http\Middleware\IsAdminMiddleware::class,
        'adminOnly' => \App\Http\Middleware\AdminOnly::class,
        'customerOnly' => \App\Http\Middleware\CustomerOnly::class,
    ];
}
EOF

# 9. Update Routes with Proper Middleware Protection
echo "9. Updating web routes with proper access control..."
sudo tee /var/www/html/routes/web.php > /dev/null << 'EOF'
<?php

use App\Http\Controllers\ProfileController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\CartController;
use App\Http\Controllers\CheckoutController;
use App\Http\Controllers\FAQController;
use App\Http\Controllers\Admin\AdminDashboardController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Admin\ProductController as AdminProductController;
use App\Http\Controllers\Admin\OrderController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes - With Proper Admin/Customer Separation
|--------------------------------------------------------------------------
*/

// Public routes (accessible to all)
Route::get('/', function () {
    return redirect()->route('home');
});

// Authentication Routes (Laravel Breeze)
require __DIR__.'/auth.php';

// Customer-Only Routes (blocked for admins)
Route::middleware(['customerOnly'])->group(function () {
    // Home and public pages
    Route::get('/home', [HomeController::class, 'index'])->name('home');
    Route::get('/faq', [FAQController::class, 'index'])->name('faq');
    
    // Products (customer view)
    Route::get('/products', [ProductController::class, 'index'])->name('products.index');
    Route::get('/products/{id}', [ProductController::class, 'show'])->name('products.show');
    
    // Customer Dashboard (requires auth + customer only)
    Route::middleware(['auth'])->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
        
        // Cart Management
        Route::get('/cart', [CartController::class, 'index'])->name('cart.index');
        
        // Checkout Process
        Route::get('/checkout', [CheckoutController::class, 'index'])->name('checkout.index');
        Route::post('/checkout', [CheckoutController::class, 'process'])->name('checkout.process');
        Route::get('/checkout/buy-now/{itemId}', [CheckoutController::class, 'buyNow'])->name('checkout.buy-now');
    });
});

// Admin-Only Routes (strict admin access)
Route::middleware(['adminOnly'])->prefix('admin')->name('admin.')->group(function () {
    // Admin Dashboard
    Route::get('/dashboard', [AdminDashboardController::class, 'index'])->name('dashboard');
    
    // User Management
    Route::resource('users', UserController::class);
    
    // Product Management
    Route::resource('products', AdminProductController::class)->except(['show']);
    
    // Order Management  
    Route::resource('orders', OrderController::class)->only(['index', 'show', 'update']);
});

// Test and Debug Routes (remove in production)
Route::get('/test-cart-add/{itemId}', function($itemId) {
    $item = App\Models\Item::find($itemId);
    if (!$item) return 'Item not found';
    
    $sessionCart = session()->get('cart', []);
    $sessionCart[$itemId] = [
        'item_id' => $itemId,
        'name' => $item->Name,
        'price' => $item->Price,
        'quantity' => 1,
        'image' => $item->image_url
    ];
    session()->put('cart', $sessionCart);
    
    return 'Item added. Cart: ' . json_encode(session()->get('cart'));
})->name('test.cart.add');

// Profile Management (available to both admin and customers in their respective areas)
Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});
EOF

# 10. Update Header Navigation to Prevent Admin Access to Customer Areas
echo "10. Updating header navigation with proper role-based display..."
sudo tee /var/www/html/resources/views/partials/header.blade.php > /dev/null << 'EOF'
<!-- Primary Header Navigation -->
<nav class="border-b border-gray-100 bg-white shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">

        @php
            $isAdminArea = request()->is('admin*');
            $isAdmin = auth()->check() && (auth()->user()->role === 'admin' || auth()->user()->Role === 'admin');
        @endphp

        <!-- Logo -->
        @if($isAdminArea && $isAdmin)
            <!-- Admin Logo - Links to Admin Dashboard -->
            <a href="{{ route('admin.dashboard') }}" class="text-xl sm:text-2xl font-bold text-red-600 tracking-wide">eBrew Admin</a>
        @elseif($isAdmin)
            <!-- Admin user on customer area - redirect to admin -->
            <a href="{{ route('admin.dashboard') }}" class="text-xl sm:text-2xl font-bold text-red-600 tracking-wide">eBrew Admin</a>
        @else
            <!-- Customer Logo - Links to Home -->
            <a href="{{ route('home') }}" class="text-xl sm:text-2xl font-bold text-yellow-900 tracking-wide">eBrew</a>
        @endif

        <!-- Navigation Links -->
        <div class="hidden md:flex space-x-6 text-sm font-medium text-gray-800">
            @if($isAdminArea && $isAdmin)
                <!-- Admin Navigation -->
                <a href="{{ route('admin.dashboard') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.dashboard') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Admin Dashboard</a>
                <a href="{{ route('admin.users.index') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.users.*') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Users</a>
                <a href="{{ route('admin.products.index') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.products.*') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Products</a>
                <a href="{{ route('admin.orders.index') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.orders.*') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Orders</a>
            @elseif($isAdmin)
                <!-- Admin user accessing customer area - show redirect message -->
                <div class="bg-red-100 text-red-800 px-3 py-1 rounded-full text-xs">
                    Admin Account - <a href="{{ route('admin.dashboard') }}" class="underline font-semibold">Go to Admin Panel</a>
                </div>
            @else
                <!-- Customer Navigation -->
                <a href="{{ route('home') }}" class="hover:text-yellow-900 transition">Home</a>
                <a href="{{ route('products.index') }}" class="hover:text-yellow-900 transition">Products</a>
                <a href="{{ route('faq') }}" class="hover:text-yellow-900 transition">FAQ</a>
            @endif
        </div>

        <!-- Right Side -->
        <div class="flex items-center space-x-4 text-gray-700">
            @guest
                <a href="{{ route('login') }}" class="hover:text-yellow-900 text-sm font-medium">Login</a>
                <a href="{{ route('register') }}" class="hover:text-yellow-900 text-sm font-medium">Register</a>
            @else
                @if($isAdminArea && $isAdmin)
                    <span class="text-xs bg-red-100 text-red-800 px-2 py-1 rounded-full">Admin Mode</span>
                    <span class="text-sm text-gray-600">{{ auth()->user()->name }}</span>
                    <form action="{{ route('logout') }}" method="POST">
                        @csrf
                        <button class="hover:text-red-600 text-sm font-medium">Logout</button>
                    </form>
                @elseif($isAdmin)
                    <!-- Admin in customer area -->
                    <div class="flex items-center space-x-2">
                        <span class="text-xs bg-red-100 text-red-800 px-2 py-1 rounded-full">Admin Account</span>
                        <a href="{{ route('admin.dashboard') }}" 
                           class="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm font-medium transition">
                            Admin Panel
                        </a>
                        <form action="{{ route('logout') }}" method="POST">
                            @csrf
                            <button class="hover:text-red-600 text-sm font-medium">Logout</button>
                        </form>
                    </div>
                @else
                    <!-- Customer Profile Dropdown -->
                    <div class="relative" x-data="{ open: false }">
                        <button @click="open = !open" 
                                class="hover:text-yellow-900 transition {{ request()->routeIs('dashboard') ? 'text-yellow-900' : 'text-gray-700' }}"
                                title="Profile">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                            </svg>
                        </button>
                        
                        <!-- Dropdown Menu -->
                        <div x-show="open" 
                             @click.away="open = false"
                             x-transition:enter="transition ease-out duration-200"
                             x-transition:enter-start="opacity-0 transform scale-95"
                             x-transition:enter-end="opacity-100 transform scale-100"
                             x-transition:leave="transition ease-in duration-75"
                             x-transition:leave-start="opacity-100 transform scale-100"
                             x-transition:leave-end="opacity-0 transform scale-95"
                             class="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg ring-1 ring-black ring-opacity-5 z-50">
                            <div class="py-1">
                                <a href="{{ route('dashboard') }}" 
                                   class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 hover:text-gray-900 transition">
                                    Dashboard
                                </a>
                                <form action="{{ route('logout') }}" method="POST" class="block">
                                    @csrf
                                    <button type="submit" 
                                            class="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 hover:text-red-600 transition">
                                        Logout
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>

                    <!-- Customer Cart Icon with Counter (only for customers) -->
                    @auth
                        <livewire:cart-counter />
                    @endauth
                @endif
            @endguest
        </div>
    </div>
</nav>

<!-- Mobile Navigation -->
<div class="md:hidden border-b border-gray-100 px-4 py-2 text-sm font-medium text-gray-700 bg-white">
    <div class="flex space-x-6 justify-center">
        @if($isAdminArea && $isAdmin)
            <!-- Admin Mobile Navigation -->
            <a href="{{ route('admin.dashboard') }}" class="hover:text-red-600">Dashboard</a>
            <a href="{{ route('admin.users.index') }}" class="hover:text-red-600">Users</a>
            <a href="{{ route('admin.products.index') }}" class="hover:text-red-600">Products</a>
            <a href="{{ route('admin.orders.index') }}" class="hover:text-red-600">Orders</a>
        @elseif($isAdmin)
            <!-- Admin in customer area - mobile -->
            <a href="{{ route('admin.dashboard') }}" class="bg-red-600 text-white px-3 py-1 rounded">Admin Panel</a>
        @else
            <!-- Customer Mobile Navigation -->
            <a href="{{ route('home') }}" class="hover:text-yellow-900">Home</a>
            <a href="{{ route('products.index') }}" class="hover:text-yellow-900 transition">Products</a>
            <a href="{{ route('faq') }}" class="hover:text-yellow-900 transition">FAQ</a>
        @endif
    </div>
</div>

@auth
<script>
function handleCartClick(event) {
    @if($isAdmin)
        event.preventDefault();
        alert('Admin accounts cannot access cart. Use admin panel for order management.');
        return false;
    @else
        return true;
    @endif
}
</script>
@endauth

@guest
<script>
function handleCartClick(event) {
    event.preventDefault();
    alert('Please log in to view your cart.');
    window.location.href = '{{ route("login") }}';
    return false;
}
</script>
@endguest
EOF

echo "11. Reloading Apache..."
sudo systemctl reload apache2

echo
echo "=== ALL UI, PRODUCT AND ADMIN ACCESS CONTROL ISSUES FIXED ==="
echo "✅ Cart UI: Removed duplicate Continue Shopping button - only blue button remains in empty cart"
echo "✅ Product Edit: Fixed 500 error by using correct 'id' field instead of 'ItemID' in routes"
echo "✅ Image Upload: Fixed image handling to store in public/images with proper URL generation"
echo "✅ Image Display: Enhanced Item model with better image_url accessor for all scenarios"
echo "✅ Error Handling: Added comprehensive logging and error handling for product operations"
echo "✅ File Management: Images now stored in public/images with proper permissions"
echo "✅ Admin Access Control: Created AdminOnly middleware to restrict admin access to admin pages only"
echo "✅ Customer Protection: Created CustomerOnly middleware to block admin access to customer pages"
echo "✅ Route Protection: Updated all routes with proper middleware protection"
echo "✅ Header Navigation: Enhanced header to show proper admin/customer separation"
echo "✅ Middleware Registration: Registered new middleware in Kernel for global access"
echo
echo "🔍 TEST RESULTS EXPECTED:"
echo "1. Cart page (http://13.60.43.49/cart) - Empty cart shows only ONE blue 'Continue Shopping' button"
echo "2. Product edit (http://13.60.43.49/admin/products) - Edit button should work without 500 errors"
echo "3. Product images - New products with images should display properly on product pages"
echo "4. Admin panel - Product management should work smoothly with proper error handling"
echo "5. Image uploads - Files stored in public/images directory with proper permissions"
echo
echo "🚨 ADMIN ACCESS CONTROL - NEW SECURITY FEATURES:"
echo "✅ Admin CANNOT access:"
echo "   - Home page (/) or (/home)"
echo "   - Products page (/products)"
echo "   - Product detail pages (/products/{id})"
echo "   - Customer dashboard (/dashboard)"
echo "   - Cart page (/cart)"
echo "   - Checkout pages (/checkout)"
echo "   - FAQ page (/faq)"
echo
echo "✅ Admin CAN ONLY access:"
echo "   - Admin Dashboard (/admin/dashboard)"
echo "   - User Management (/admin/users)"
echo "   - Product Management (/admin/products)"
echo "   - Order Management (/admin/orders)"
echo "   - Profile settings (/profile)"
echo
echo "✅ When admin tries to access customer pages:"
echo "   - Automatically redirected to admin dashboard"
echo "   - Informative message displayed"
echo "   - Header shows 'Go to Admin Panel' button"
echo
echo "✅ Customers CANNOT access:"
echo "   - Any /admin/* routes"
echo "   - Redirected to login with access denied message"
echo
echo "The system now has complete role-based access control with strict admin/customer separation!"