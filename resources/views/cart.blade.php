@extends('layouts.app')

@section('title', 'Your Cart - eBrew Café')

@section('content')
<div class="max-w-7xl mx-auto px-4 py-12">
    <h2 class="text-3xl font-bold mb-8">Your Cart</h2>

    @if(session('cart') && count(session('cart')) > 0)
        @php
            $cartItems = session('cart');
            $subtotal = 0;
            foreach ($cartItems as $item) {
                $subtotal += $item['price'] * $item['quantity'];
            }
        @endphp

        <div class="grid lg:grid-cols-3 gap-8">
            <!-- Cart Items -->
            <div class="lg:col-span-2 space-y-6">
                @foreach($cartItems as $item)
                    <div class="flex flex-col md:flex-row items-center justify-between border rounded-lg p-4 shadow-sm mb-4">
                        <!-- Image + Name -->
                        <div class="flex items-center gap-4 w-full md:w-1/3 mb-4 md:mb-0">
                            <img src="{{ $item['image'] }}" alt="{{ $item['name'] }}" class="w-16 h-16 object-cover border rounded">
                            <p class="font-semibold">{{ $item['name'] }}</p>
                        </div>

                        <!-- Price -->
                        <p class="font-bold text-xl text-center w-full md:w-1/3 mb-4 md:mb-0">
                            Rs.{{ number_format($item['price'], 2) }}
                        </p>

                        <!-- Qty controls + Delete -->
                        <div class="flex justify-center md:justify-end items-center space-x-2 w-full md:w-1/3">
                            <form action="{{ url('/cart/update') }}" method="POST" class="flex items-center space-x-2">
                                @csrf
                                <input type="hidden" name="product_id" value="{{ $item['product_id'] }}">
                                <button type="submit" name="action" value="decrement" class="px-3 py-1 rounded bg-gray-200 hover:bg-gray-300 text-lg" {{ $item['quantity'] <= 1 ? 'disabled' : '' }}>−</button>
                                <span class="px-3">{{ $item['quantity'] }}</span>
                                <button type="submit" name="action" value="increment" class="px-3 py-1 rounded bg-gray-200 hover:bg-gray-300 text-lg">+</button>
                            </form>
                            <form action="{{ url('/cart/remove') }}" method="POST">
                                @csrf
                                <input type="hidden" name="product_id" value="{{ $item['product_id'] }}">
                                <button type="submit" class="p-2 rounded-full bg-red-100 hover:bg-red-200 text-red-600 transition" title="Remove Item">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24"
                                        stroke="currentColor" stroke-width="2">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                                    </svg>
                                </button>
                            </form>
                        </div>
                    </div>
                @endforeach
            </div>

            <!-- Summary -->
            <div class="bg-gray-100 p-6 rounded-lg shadow-md h-fit">
                <h3 class="text-xl font-semibold mb-4">
                    Summary ({{ count($cartItems) }} item{{ count($cartItems) > 1 ? 's' : '' }})
                </h3>
                <div class="flex justify-between mb-2 text-sm"><span>Subtotal</span><span>Rs.{{ number_format($subtotal, 2) }}</span></div>
                <div class="flex justify-between mb-2 text-sm"><span>Shipping</span><span>–</span></div>
                <div class="flex justify-between mb-4 text-sm"><span>Est. Taxes</span><span>–</span></div>
                <hr class="border-gray-300 mb-4">
                <div class="flex justify-between font-bold text-lg mb-6"><span>Total</span><span>Rs.{{ number_format($subtotal, 2) }}</span></div>
                <a href="{{ url('/checkout') }}" class="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 rounded font-semibold text-center block">
                    Checkout
                </a>
            </div>
        </div>

    @else
        <div class="flex flex-col items-center justify-center text-center py-20 px-4 bg-gray-50 rounded-lg shadow-sm">
            <img src="https://cdn-icons-png.flaticon.com/512/2038/2038854.png" alt="Empty Cart"
                class="w-28 h-28 mb-6 opacity-80">
            <h2 class="text-3xl font-bold text-yellow-900 mb-2">Your Cart is Empty</h2>
            <p class="text-gray-600 mb-6 max-w-md">
                Looks like you haven’t added anything to your cart yet. Discover our handcrafted coffee selections!
            </p>
            <a href="{{ url('/products') }}"
                class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded text-sm font-semibold transition">
                Explore Products
            </a>
        </div>
    @endif
</div>
@endsection
