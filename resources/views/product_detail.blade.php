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
                <p>{{ $product->RoastDates ?? 'N/A' }}</p>
            </div>
        </div>

        <!-- Add to Cart Component -->
        <div class="mt-6">
            <livewire:add-to-cart :item-id="$product->ItemID" />
        </div>

    </div>

</main>

@endsection
