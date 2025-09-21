@extends('layouts.app')

@section('content')
<div class="max-w-6xl mx-auto px-6 py-8 space-y-10 mt-5 mb-10">
    <!-- Welcome Section -->
    <div class="text-center">
        <h1 class="text-4xl font-bold text-yellow-900">
            Welcome, {{ $user->name }}!
        </h1>
    </div>

    <!-- Profile Card -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div class="bg-white rounded-2xl shadow-lg p-6 flex flex-col items-center">
            <div class="w-24 h-24 bg-yellow-100 text-yellow-800 flex items-center justify-center rounded-full text-3xl mb-4">
                <i class="fas fa-user"></i>
            </div>
            <h2 class="text-xl font-semibold text-gray-800">{{ $user->name }}</h2>
            <p class="text-sm text-gray-500 mb-4">{{ $user->email }}</p>
            <a href="{{ route('profile.edit') }}" class="bg-yellow-600 hover:bg-yellow-700 text-white px-4 py-2 rounded-md text-sm">Edit Profile</a>
        </div>

        <!-- Orders -->
        <div class="lg:col-span-2">
            <div class="bg-white rounded-2xl shadow-lg p-6">
                <h2 class="text-xl font-bold text-gray-800 mb-4">Recent Orders</h2>
                <table class="w-full text-sm text-left border rounded-xl overflow-hidden">
                    <thead class="bg-gray-100 text-gray-600 uppercase text-xs">
                        <tr>
                            <th class="px-4 py-2">Order #</th>
                            <th class="px-4 py-2">Date</th>
                            <th class="px-4 py-2">Items</th>
                            <th class="px-4 py-2">Total</th>
                            <th class="px-4 py-2">Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($orders as $order)
                            <tr class="hover:bg-gray-50">
                                <td class="px-4 py-3 font-medium">#{{ $order->OrderID }}</td>
                                <td class="px-4 py-3">{{ \Carbon\Carbon::parse($order->OrderDate)->format('M d, Y') }}</td>
                                <td class="px-4 py-3">{{ $order->items_summary ?? 'N/A' }}</td>
                                <td class="px-4 py-3">Rs {{ number_format($order->SubTotal ?? 0, 2) }}</td>
                                <td class="px-4 py-3 text-green-600 font-semibold">{{ $order->status ?? 'Pending' }}</td>
                            </tr>
                        @empty
                            <tr><td colspan="5" class="px-4 py-3 text-gray-500">No orders found.</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Recommended -->
    <div class="bg-white rounded-2xl shadow-lg p-6">
        <h2 class="text-xl font-bold text-gray-800 mb-6">Recommended for You</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
            @forelse($recommended as $product)
                <div class="border rounded-xl p-4 shadow hover:shadow-md text-center transition duration-300">
                    <img src="{{ asset('images/uploads/'.$product->ProductID.'.png') }}" class="h-32 w-32 mx-auto mb-3 rounded object-cover">
                    <p class="font-semibold text-gray-800">{{ $product->Name }}</p>
                    <p class="text-sm text-gray-500">Rs {{ number_format($product->Price, 2) }}</p>
                    <button class="mt-3 bg-green-600 hover:bg-green-700 text-white px-4 py-1 rounded text-sm">Add to Cart</button>
                </div>
            @empty
                <p class="text-gray-600">No recommendations available right now.</p>
            @endforelse
        </div>
    </div>
</div>
@endsection
