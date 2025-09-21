@extends('layouts.public')

@section('title', 'Our Menu - eBrew Café')

@section('content')
<div class="container mx-auto px-4 py-8">
    <div class="text-center mb-8">
        <h1 class="text-4xl font-bold text-gray-800 mb-4">Our Menu</h1>
        <p class="text-gray-600 text-lg">Discover our carefully crafted beverages and delicious treats</p>
        
        <!-- Cart Counter Display -->
        <div class="mt-4">
            <livewire:cart-counter />
        </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        @forelse($items as $item)
            <div class="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow duration-300">
                <a href="{{ route('items.show', $item->ItemID) }}" class="block">
                    <div class="aspect-w-16 aspect-h-9">
                        <img 
                            src="{{ $item->image_url }}" 
                            alt="{{ $item->Name }}"
                            class="w-full h-48 object-cover hover:scale-105 transition-transform duration-300"
                            onerror="this.src='/images/default-product.png'"
                        >
                    </div>
                </a>
                
                <div class="p-4">
                    <a href="{{ route('items.show', $item->ItemID) }}">
                        <h3 class="text-lg font-semibold text-gray-800 mb-2 hover:text-yellow-600 transition-colors">{{ $item->Name }}</h3>
                    </a>
                    <p class="text-gray-600 text-sm mb-3">{{ Str::limit($item->Description, 80) }}</p>
                    
                    <div class="flex items-center justify-between mb-4">
                        <span class="text-2xl font-bold text-yellow-600">${{ number_format($item->Price, 2) }}</span>
                        <span class="px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">
                            Beverage
                        </span>
                    </div>
                    
                    <!-- Livewire Add to Cart Component -->
                    <livewire:add-to-cart :item-id="$item->ItemID" />
                </div>
            </div>
        @empty
            <div class="col-span-full text-center py-8">
                <div class="text-gray-400 mb-4">
                    <i class="fas fa-coffee text-6xl"></i>
                </div>
                <h3 class="text-xl font-semibold text-gray-600 mb-2">No Items Available</h3>
                <p class="text-gray-500">We're currently updating our menu. Please check back soon!</p>
            </div>
        @endforelse
    </div>
    
    @if($items->count() > 0)
        <div class="text-center mt-8">
            <a href="{{ route('cart.index') }}" 
               class="inline-flex items-center px-6 py-3 bg-yellow-500 text-white font-semibold rounded-lg hover:bg-yellow-600 transition-colors duration-200">
                <i class="fas fa-shopping-cart mr-2"></i>
                View Cart
            </a>
        </div>
    @endif
</div>

<style>
@keyframes pulse {
    0%, 100% { transform: scale(1); }
    50% { transform: scale(1.05); }
}

.cart-badge {
    animation: pulse 0.5s ease-in-out;
}
</style>
@endsection