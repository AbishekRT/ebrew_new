@extends('layouts.public')

@section('title', $item->Name . ' - eBrew Café')

@section('content')
<div class="container mx-auto px-4 py-8">
    <div class="max-w-6xl mx-auto">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <!-- Item Image -->
            <div class="aspect-w-1 aspect-h-1">
                <img 
                    src="{{ $item->image_url }}" 
                    alt="{{ $item->Name }}"
                    class="w-full h-96 object-cover rounded-lg shadow-lg"
                    onerror="this.src='/images/default-product.png'"
                >
            </div>
            
            <!-- Item Details -->
            <div class="space-y-6">
                <div>
                    <h1 class="text-3xl font-bold text-gray-800 mb-2">{{ $item->Name }}</h1>
                    <div class="flex items-center space-x-4 mb-4">
                        <span class="text-3xl font-bold text-yellow-600">${{ number_format($item->Price, 2) }}</span>
                        <span class="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm font-medium">
                            Beverage
                        </span>
                    </div>
                </div>
                
                <div>
                    <h3 class="text-lg font-semibold text-gray-800 mb-2">Description</h3>
                    <p class="text-gray-600 leading-relaxed">{{ $item->Description }}</p>
                </div>
                
                <div class="border-t pt-6">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4">Add to Cart</h3>
                    <!-- Livewire Add to Cart Component -->
                    <livewire:add-to-cart :item-id="$item->ItemID" />
                </div>
                
                <!-- Real-time Cart Counter -->
                <div class="border-t pt-6">
                    <div class="flex items-center justify-between">
                        <span class="text-gray-600">Items in cart:</span>
                        <livewire:cart-counter />
                    </div>
                </div>
                
                <div class="border-t pt-6">
                    <div class="flex space-x-4">
                        <a href="{{ route('products.index') }}" 
                           class="flex-1 px-4 py-2 border border-gray-300 text-gray-700 font-medium rounded-lg hover:bg-gray-50 transition-colors duration-200 text-center">
                            <i class="fas fa-arrow-left mr-2"></i>
                            Back to Products
                        </a>
                        
                        <a href="{{ route('cart.index') }}" 
                           class="flex-1 px-4 py-2 bg-yellow-500 text-white font-medium rounded-lg hover:bg-yellow-600 transition-colors duration-200 text-center">
                            <i class="fas fa-shopping-cart mr-2"></i>
                            View Cart
                        </a>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Additional Information -->
        <div class="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6">
            <div class="text-center p-6 bg-gray-50 rounded-lg">
                <i class="fas fa-coffee text-3xl text-yellow-500 mb-3"></i>
                <h4 class="font-semibold text-gray-800 mb-2">Fresh Quality</h4>
                <p class="text-gray-600 text-sm">Made with the finest ingredients</p>
            </div>
            
            <div class="text-center p-6 bg-gray-50 rounded-lg">
                <i class="fas fa-shipping-fast text-3xl text-yellow-500 mb-3"></i>
                <h4 class="font-semibold text-gray-800 mb-2">Quick Service</h4>
                <p class="text-gray-600 text-sm">Fast and efficient preparation</p>
            </div>
            
            <div class="text-center p-6 bg-gray-50 rounded-lg">
                <i class="fas fa-heart text-3xl text-yellow-500 mb-3"></i>
                <h4 class="font-semibold text-gray-800 mb-2">Made with Love</h4>
                <p class="text-gray-600 text-sm">Crafted by our expert baristas</p>
            </div>
        </div>
    </div>
</div>
@endsection