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

                        {{-- Debug ID labels removed for cleaner UI --}}

                    @if($product && isset($product->id) && $product->id)
                        </a>
                    @else
                        </div>
                    @endif
                @empty
                    <p class="text-gray-500">No products available.</p>
                @endforelse
            </div>
        </div>
    @endforeach

</section>

@endsection
