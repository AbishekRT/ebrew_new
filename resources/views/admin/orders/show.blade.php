@extends('layouts.app')

@section('content')
<div class="min-h-screen font-sans bg-[#F9F6F1] p-10 text-[#2D1B12]">
    <!-- Page Title -->
    <h1 class="text-3xl font-bold mb-10 text-center">Order Details #{{ $order->OrderID }}</h1>

    <!-- Order Information Card -->
    <div class="bg-white p-6 rounded-xl shadow-md border border-gray-200 mb-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Order Info -->
            <div>
                <h2 class="text-xl font-semibold mb-4 text-[#2D1B12]">Order Information</h2>
                <div class="space-y-2">
                    <p><span class="font-medium">Order ID:</span> #{{ $order->OrderID }}</p>
                    <p><span class="font-medium">Order Date:</span> {{ \Carbon\Carbon::parse($order->OrderDate)->format('M d, Y h:i A') }}</p>
                    <p><span class="font-medium">Total Amount:</span> <span class="font-bold text-[#7C4D2B]">Rs {{ number_format($order->SubTotal ?? 0, 2) }}</span></p>
                </div>
            </div>

            <!-- Customer Info -->
            <div>
                <h2 class="text-xl font-semibold mb-4 text-[#2D1B12]">Customer Information</h2>
                <div class="space-y-2">
                    <p><span class="font-medium">Name:</span> {{ $order->user->name ?? 'Unknown' }}</p>
                    <p><span class="font-medium">Email:</span> {{ $order->user->email ?? 'N/A' }}</p>
                    <p><span class="font-medium">Phone:</span> {{ $order->user->Phone ?? 'N/A' }}</p>
                    <p><span class="font-medium">Address:</span> {{ $order->user->DeliveryAddress ?? 'N/A' }}</p>
                </div>
            </div>
        </div>
    </div>

    <!-- Order Items -->
    @if($order->orderItems && $order->orderItems->count() > 0)
        <div class="bg-white p-6 rounded-xl shadow-md border border-gray-200 mb-6">
            <h2 class="text-xl font-semibold mb-4 text-[#2D1B12]">Order Items</h2>
            <div class="overflow-hidden">
                <table class="w-full text-left">
                    <thead class="bg-gray-50">
                        <tr>
                            <th class="px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Product</th>
                            <th class="px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Price</th>
                            <th class="px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Quantity</th>
                            <th class="px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Subtotal</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200">
                        @foreach($order->orderItems as $item)
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="flex items-center">
                                        @if($item->item && $item->item->Image)
                                            <img src="{{ $item->item->image_url }}" alt="{{ $item->item->Name ?? 'Product' }}" class="w-12 h-12 rounded-lg object-cover mr-4">
                                        @elseif($item->item)
                                            <div class="w-12 h-12 bg-gray-200 rounded-lg mr-4 flex items-center justify-center">
                                                <span class="text-gray-400 text-xs">No Image</span>
                                            </div>
                                        @endif
                                        <div>
                                            <div class="font-medium text-gray-900">{{ $item->item->Name ?? 'Unknown Product' }}</div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-gray-700">
                                    Rs {{ number_format($item->Price ?? $item->item->Price ?? 0, 2) }}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-gray-700">
                                    {{ $item->Quantity ?? 0 }}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap font-medium text-[#7C4D2B]">
                                    Rs {{ number_format(($item->Price ?? $item->item->Price ?? 0) * ($item->Quantity ?? 0), 2) }}
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    @else
        <div class="bg-white p-6 rounded-xl shadow-md border border-gray-200 mb-6 text-center">
            <p class="text-gray-500">No items found for this order.</p>
        </div>
    @endif

    <!-- Action Buttons -->
    <div class="flex justify-center space-x-4">
        <a href="{{ route('admin.orders.index') }}" 
           class="bg-gray-500 hover:bg-gray-600 text-white font-semibold px-6 py-3 rounded-lg transition">
            ← Back to Orders
        </a>
    </div>
</div>
@endsection