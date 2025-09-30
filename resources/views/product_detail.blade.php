@extends('layouts.app')

@section('title', $product->Name ?? 'Product - eBrew Café')

@section('content')

<main class="max-w-7xl mx-auto px-6 py-10 grid grid-cols-1 md:grid-cols-2 gap-10">

    <!-- Product Image -->
    <div class="flex justify-center items-start">
        <img src="{{ $product->image_url }}" 
             alt="{{ $product->Name ?? 'Product' }}" 
             class="w-full max-w-xs object-cover">
    </div>

    <!-- Product Details -->
    <div class="space-y-6">

        <!-- Name & Price -->
        <div>
            <h1 class="text-2xl font-semibold text-gray-900">
                {{ $product->Name ?? 'Unnamed Product' }}
            </h1>
            <p class="text-lg font-medium text-gray-800 mt-1">
                Rs.{{ number_format($product->Price ?? 0, 2) }}
            </p>
        </div>

        <!-- Description -->
        <p class="text-gray-700 leading-relaxed">
            {!! nl2br(e($product->Description ?? 'No description available')) !!}
        </p>

        <hr class="border-gray-300">

        <!-- Extra Details -->
        <div class="space-y-4 text-sm text-gray-700">
            <div>
                <p class="font-bold">Taste Notes</p>
                <p>{!! nl2br(e($product->TastingNotes ?? 'N/A')) !!}</p>
            </div>

            <div>
                <p class="font-bold">Shipping and Returns</p>
                <p>{!! nl2br(e($product->ShippingAndReturns ?? 'N/A')) !!}</p>
            </div>

            <div>
                <p class="font-bold">Roast Date</p>
                <p>{{ $product->RoastDates ? \Carbon\Carbon::parse($product->RoastDates)->format('Y-m-d') : 'N/A' }}</p>
            </div>
        </div>

        <!-- Add to Cart Component -->
        <div class="mt-6">
            <livewire:add-to-cart :item-id="$product->id" />
        </div>

    </div>

</main>

<!-- Feature Tabs Section -->
<section class="max-w-7xl mx-auto px-6 py-12">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
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
</section>

@endsection
