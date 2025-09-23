@extends('layouts.app')

@section('title', 'Checkout - eBrew Café')

@section('content')
<div class="max-w-4xl mx-auto px-6 py-8">
    <h1 class="text-3xl font-bold text-gray-800 mb-8">Checkout</h1>
    
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Order Summary -->
        <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold text-gray-800 mb-4">Order Summary</h2>
            
            <div class="space-y-4">
                @foreach($cart->items as $item)
                    <div class="flex items-center space-x-4">
                        <img src="{{ $item->item->image_url }}" 
                             alt="{{ $item->item->Name }}" 
                             class="w-16 h-16 object-cover rounded">
                        <div class="flex-1">
                            <h3 class="font-medium text-gray-800">{{ $item->item->Name }}</h3>
                            <p class="text-sm text-gray-600">Quantity: {{ $item->Quantity }}</p>
                        </div>
                        <div class="text-right">
                            <p class="font-semibold text-gray-800">
                                Rs. {{ number_format($item->item->Price * $item->Quantity, 2) }}
                            </p>
                        </div>
                    </div>
                @endforeach
            </div>
            
            <div class="border-t mt-6 pt-4">
                <div class="flex justify-between items-center text-xl font-bold text-gray-800">
                    <span>Total:</span>
                    <span>Rs. {{ number_format($cart->total, 2) }}</span>
                </div>
            </div>
        </div>

        <!-- Customer Details -->
        <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold text-gray-800 mb-4">Customer Details</h2>
            
            <form method="POST" action="{{ route('checkout.process') }}" class="space-y-4">
                @csrf
                
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Name</label>
                    <input type="text" value="{{ $user->name }}" 
                           class="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50" readonly>
                </div>
                
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Email</label>
                    <input type="email" value="{{ $user->email }}" 
                           class="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50" readonly>
                </div>
                
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Phone (Optional)</label>
                    <input type="tel" name="phone" 
                           class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500">
                </div>
                
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Address (Optional)</label>
                    <textarea name="address" rows="3"
                              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500"></textarea>
                </div>
                
                <button type="submit" 
                        class="w-full bg-yellow-600 hover:bg-yellow-700 text-white font-semibold py-3 px-4 rounded-md transition-colors">
                    <i class="fas fa-credit-card mr-2"></i>
                    Place Order (Rs. {{ number_format($cart->total, 2) }})
                </button>
            </form>
        </div>
    </div>
</div>
@endsection