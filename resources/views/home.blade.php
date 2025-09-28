@extends('layouts.public')

@section('title', 'Home - eBrew Café')

@section('content')
    <!-- Hero Section with Overlay -->
    <div class="relative w-full h-80 sm:h-[500px]">
        <img src="{{ asset('images/B2.png') }}" alt="Hero Image" class="w-full h-full object-cover">
        <div class="absolute inset-0 bg-black bg-opacity-50 flex items-center justify-center">
            <div class="text-center text-white px-4">
                <h1 class="text-3xl sm:text-5xl font-bold mb-2">Welcome to eBrew Café</h1>
                <p class="text-lg sm:text-xl">Your favorite brews & gadgets in one place.</p>
            </div>
        </div>
    </div>

    <!-- Best Selling Section -->
    <section class="bg-gray-50 py-16">
        <div class="max-w-7xl mx-auto px-6">
            <h2 class="text-3xl font-extrabold text-gray-800 text-center mb-12">
                Explore Best Selling Products
            </h2>

            <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-10">
                @forelse($featuredProducts as $product)
                    <a href="{{ url('products/'.$product->id) }}" 
                       class="group bg-white rounded-lg shadow-md p-4 transition hover:shadow-xl">
                        <img src="{{ $product->image_url }}" 
                             alt="{{ $product->Name }}" 
                             class="h-44 mx-auto object-contain mb-4 transition-transform duration-300 group-hover:scale-105">
                        <h3 class="text-sm font-semibold text-center text-gray-800">{{ $product->Name }}</h3>
                        <p class="text-red-600 font-bold text-center mt-2">Rs. {{ number_format($product->Price, 2) }}</p>
                    </a>
                @empty
                    <div class="col-span-full text-center py-8">
                        <p class="text-gray-500 text-lg">No products available at the moment.</p>
                        <p class="text-gray-400 text-sm mt-2">Please check back later!</p>
                    </div>
                @endforelse
            </div>
        </div>
    </section>
@endsection
