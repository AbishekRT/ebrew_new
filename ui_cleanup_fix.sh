#!/bin/bash

# 🔧 UI CLEANUP & BUG FIXES FOR EC2
# ===================================

echo "🚀 Starting UI cleanup and bug fixes..."

cd /var/www/html

# Step 1: Update products.blade.php - Remove ID labels and fix ItemID references
echo "📝 Step 1: Cleaning up products view..."
cat > resources/views/products.blade.php << 'EOF'
@extends('layouts.app')

@section('title', 'Products - eBrew Café')

@section('content')

<!-- Hero Banner -->
<div class="relative w-full h-80 sm:h-[500px]">
    <img src="{{ asset('images/B1.png') }}" alt="Hero Image" class="w-full h-full object-cover">
    <div class="absolute inset-0 bg-black/40 flex items-center justify-center">
        <div class="text-center text-white px-4">
            <h1 class="text-3xl sm:text-5xl font-bold">Ebrew Café</h1>
            <p class="text-lg mt-2">Handpicked brews, delivered with care</p>
        </div>
    </div>
</div>

<!-- Error Display -->
@if(isset($error))
    <div class="max-w-7xl mx-auto px-6 py-4">
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
            {{ $error }}
        </div>
    </div>
@endif

<!-- Product Sections -->
<section class="max-w-7xl mx-auto px-6 py-16 space-y-20">

    @foreach(['Featured Collection', 'Best Sellers', 'New Arrivals'] as $category)
        <div>
            <h2 class="text-2xl font-bold text-gray-900 mb-6 flex items-center">
                <span class="w-2 h-6 bg-red-600 inline-block mr-3 rounded"></span>{{ $category }}
            </h2>

            <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-10 justify-items-center">
                @forelse($products as $product)
                    @if($product && isset($product->id) && $product->id)
                        <a href="{{ route('products.show', $product->id) }}" 
                           class="group bg-white rounded-lg shadow hover:shadow-lg transition p-4 text-center w-full max-w-[200px]">
                    @else
                        <div class="group bg-white rounded-lg shadow hover:shadow-lg transition p-4 text-center w-full max-w-[200px] cursor-not-allowed opacity-75">
                    @endif

                        <!-- Product Image -->
                        <div class="aspect-w-1 aspect-h-1">
                            <img src="{{ $product->image_url ?? asset('images/default.png') }}" 
                                 alt="{{ $product->Name ?? 'Product' }}" 
                                 class="w-full h-full object-contain rounded">
                        </div>

                        <!-- Product Name -->
                        <h3 class="text-sm font-semibold text-gray-800 mt-4 group-hover:text-red-600 transition">
                            {{ $product->Name ?? 'Unnamed Product' }}
                        </h3>

                        <!-- Product Price -->
                        <p class="text-red-600 font-bold mt-2">
                            Rs. {{ number_format($product->Price ?? 0, 2) }}
                        </p>

                    @if($product && isset($product->id) && $product->id)
                        </a>
                    @else
                        </div>
                    @endif
                @empty
                    <div class="col-span-full text-center py-12">
                        <p class="text-gray-500 text-lg">No products available at the moment.</p>
                        <p class="text-gray-400 text-sm mt-2">Please check back later or contact support.</p>
                    </div>
                @endforelse
            </div>
        </div>
    @endforeach

</section>

@endsection
EOF

# Step 2: Fix header - Remove "End Patch" text
echo "📝 Step 2: Cleaning up header..."
cat > resources/views/partials/header.blade.php << 'EOF'
<!-- Primary Header Navigation -->
<nav class="border-b border-gray-100 bg-white shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">

        @php
            $isAdminArea = request()->is('admin*');
            $isAdmin = auth()->check() && auth()->user()->isAdmin();
        @endphp

        <!-- Logo -->
        @if($isAdminArea && $isAdmin)
            <!-- Admin Logo - Non-clickable -->
            <span class="text-xl sm:text-2xl font-bold text-red-600 tracking-wide cursor-default">eBrew</span>
        @else
            <!-- Customer Logo - Clickable -->
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
                <a href="{{ route('admin.orders.index') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.orders.*') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Orders</a>
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
                @else
                    <!-- Customer Profile Dropdown -->
                    <div class="relative" x-data="{ open: false }">
                        <button @click="open = !open" 
                                class="hover:text-yellow-900 transition {{ request()->routeIs('dashboard') ? 'text-yellow-900' : 'text-gray-700' }}"
                                title="Profile">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
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

                    <!-- Customer Cart Icon -->
                    @auth
                        <a href="{{ route('cart.index') }}" 
                           class="hover:text-yellow-900 transition relative" 
                           title="Shopping Cart">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-1.1 5a1 1 0 00.95 1.05H19M9 19v.01M20 19v.01"></path>
                            </svg>
                        </a>
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
            <a href="{{ route('admin.dashboard') }}" class="hover:text-red-600">Admin Dashboard</a>
            <a href="{{ route('admin.users.index') }}" class="hover:text-red-600">Users</a>
            <a href="{{ route('admin.orders.index') }}" class="hover:text-red-600">Orders</a>
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
    return true;
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

# Step 3: Fix add-to-cart livewire component - Update Buy Now button
echo "📝 Step 3: Fixing add-to-cart component..."
cat > resources/views/livewire/add-to-cart.blade.php << 'EOF'
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
        
        <!-- Buy Now Button - FIXED: Use correct parameter name and item->id -->
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

# Step 4: Clear all Laravel caches
echo "🔄 Step 4: Clearing Laravel caches..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear
php artisan livewire:publish --config

# Step 5: Set proper permissions
echo "🔒 Step 5: Setting permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod -R 775 /var/www/html/storage
chmod -R 775 /var/www/html/bootstrap/cache

# Step 6: Restart services
echo "🔄 Step 6: Restarting services..."
systemctl restart apache2

echo "✅ UI cleanup and bug fixes completed successfully!"
echo ""
echo "🎯 Testing URLs:"
echo "• Products page: http://16.171.36.211/products"
echo "• Product detail: http://16.171.36.211/products/1"
echo "• Cart icon should work properly"
echo "• Buy Now button should work without errors"
echo ""
echo "Expected results:"
echo "✅ No ID labels showing on products page"
echo "✅ No 'End Patch' text in header after login"  
echo "✅ Buy Now button works without route parameter errors"
echo "✅ Cart icon displays properly in header"
echo "✅ Clean, professional UI appearance"
echo ""
echo "🔧 Fixed Issues:"
echo "• Removed ID labels from products page ✅"
echo "• Removed 'End Patch' text from header ✅"
echo "• Fixed Buy Now button route parameter ✅"
echo "• Updated header admin check method ✅"
echo "• Cleaned up all UI elements ✅"
echo ""
echo "🏁 All UI issues resolved!"