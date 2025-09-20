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
                @php
                    $products = [
                        ['id' => 1, 'img' => '1.png', 'title' => 'HAVIT HV-G92 Gamepad', 'price' => '$120'],
                        ['id' => 2, 'img' => '2.png', 'title' => 'HAVIT HV-G92 Gamepad', 'price' => '$120'],
                        ['id' => 3, 'img' => '3.png', 'title' => 'HAVIT HV-G92 Gamepad', 'price' => '$120'],
                        ['id' => 4, 'img' => '4.png', 'title' => 'HAVIT HV-G92 Gamepad', 'price' => '$120'],
                        ['id' => 5, 'img' => '5.jpg', 'title' => 'HAVIT HV-G92 Gamepad', 'price' => '$120'],
                        ['id' => 6, 'img' => '6.jpg', 'title' => 'HAVIT HV-G92 Gamepad', 'price' => '$120'],
                        ['id' => 7, 'img' => '7.jpg', 'title' => 'HAVIT HV-G92 Gamepad', 'price' => '$120'],
                        ['id' => 8, 'img' => '8.jpg', 'title' => 'HAVIT HV-G92 Gamepad', 'price' => '$120'],
                    ];
                @endphp

                @foreach ($products as $product)
                    <a href="{{ url('items/'.$product['id']) }}" 
                       class="group bg-white rounded-lg shadow-md p-4 transition hover:shadow-xl">
                        <img src="{{ asset('images/'.$product['img']) }}" 
                             alt="{{ $product['title'] }}" 
                             class="h-44 mx-auto object-contain mb-4 transition-transform duration-300 group-hover:scale-105">
                        <h3 class="text-sm font-semibold text-center text-gray-800">{{ $product['title'] }}</h3>
                        <p class="text-red-600 font-bold text-center mt-2">{{ $product['price'] }}</p>
                    </a>
                @endforeach
            </div>
        </div>
    </section>
@endsection
