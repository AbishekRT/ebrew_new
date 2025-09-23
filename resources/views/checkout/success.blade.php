@extends('layouts.app')

@section('title', 'Order Confirmed - eBrew Café')

@section('content')
<div class="min-h-screen bg-[#FDFBF9] flex items-center justify-center px-6 py-12">
    <div class="max-w-6xl w-full grid grid-cols-1 md:grid-cols-2 gap-12 items-center">

        <!-- Message Section -->
        <div class="space-y-6 text-left">
            <h2 class="text-4xl font-extrabold text-yellow-900 leading-tight">
                Your brew is on its way! ☕
            </h2>
            <p class="text-gray-700 text-lg">
                Thank you for your order, <span class="font-semibold text-yellow-800">{{ $user->name }}</span>!
                We're preparing your fresh coffee and it'll be delivered right to your doorstep.
            </p>
            <p class="text-gray-600">
                Every bean is roasted with care. Until it arrives, feel free to explore more blends and flavors curated
                just for you.
            </p>
            <a href="{{ route('products.index') }}"
                class="inline-block bg-yellow-700 hover:bg-yellow-800 text-white font-medium px-6 py-3 rounded-full transition">
                ☕ Explore More Brews
            </a>
        </div>

        <!-- Illustration Section -->
        <div class="flex justify-center md:justify-end">
            <img src="{{ asset('images/B3.jpg') }}" alt="Thank you coffee"
                class="w-full max-w-md rounded-xl shadow-lg border border-yellow-200">
        </div>

    </div>
</div>
@endsection