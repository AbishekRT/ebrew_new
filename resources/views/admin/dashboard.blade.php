@extends('layouts.app')

@section('title', 'Admin Dashboard - eBrew Café')

@section('content')
<div class="min-h-screen font-sans bg-[#F9F6F1] p-10 text-[#2D1B12]">
    <!-- Page Title -->
    <h1 class="text-3xl font-bold mb-10 text-center">Admin Dashboard</h1>

    <!-- Error Message -->
    @if(isset($error))
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6 text-center">
            {{ $error }}
        </div>
    @endif

    <!-- Dashboard Summary Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
        <!-- Total Sales -->
        <div class="bg-white p-6 rounded-xl shadow-md border border-gray-200 text-center">
            <h2 class="text-lg font-semibold mb-2">Total Sales</h2>
            <p class="text-2xl font-bold text-[#7C4D2B]">
                Rs.{{ number_format($totalSales ?? 0, 2) }}
            </p>
        </div>

        <!-- Total Orders -->
        <div class="bg-white p-6 rounded-xl shadow-md border border-gray-200 text-center">
            <h2 class="text-lg font-semibold mb-2">Total Orders</h2>
            <p class="text-2xl font-bold text-[#7C4D2B]">{{ $totalOrders ?? 0 }}</p>
        </div>

        <!-- Total Products -->
        <div class="bg-white p-6 rounded-xl shadow-md border border-gray-200 text-center">
            <h2 class="text-lg font-semibold mb-2">Total Products</h2>
            <p class="text-2xl font-bold text-[#7C4D2B]">{{ $totalProducts ?? 0 }}</p>
        </div>

        <!-- Top Selling Product -->
        <div class="bg-white p-6 rounded-xl shadow-md border border-gray-200 text-center">
            <h2 class="text-lg font-semibold mb-2">Top Selling Product</h2>
            <p class="text-md font-bold text-gray-800">
                {{ $topProduct ? $topProduct->Name : 'No data' }}
            </p>
        </div>
    </div>

    <!-- Navigation Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
        @php
            $cards = [
                [
                    'title' => 'Manage Products',
                    'desc' => 'Add, edit, or delete coffee products.',
                    'link' => route('admin.products.index')
                ],
                [
                    'title' => 'Manage Users',
                    'desc' => 'Handle customer and admin accounts.',
                    'link' => route('admin.users.index')
                ],
                [
                    'title' => 'View Orders',
                    'desc' => 'Track and manage customer orders.',
                    'link' => route('admin.orders.index')
                ]
            ];
        @endphp

        @foreach ($cards as $card)
            <div class="bg-white p-6 rounded-xl shadow-md hover:shadow-lg transition border border-gray-100">
                <h3 class="font-bold text-xl mb-2">{{ $card['title'] }}</h3>
                <p class="mb-4 text-gray-700">{{ $card['desc'] }}</p>
                <a href="{{ $card['link'] }}" class="text-[#7C4D2B] hover:underline font-medium">
                    Go to {{ $card['title'] }}
                </a>
            </div>
        @endforeach
    </div>

    <!-- Sales Overview Chart -->
    <div class="bg-white p-6 rounded-xl shadow-md border border-gray-200">
        <h2 class="text-xl font-semibold mb-4">Sales Overview</h2>
        <div class="w-full h-64 bg-gray-100 flex items-center justify-center text-gray-500 rounded-lg">
            Sales chart coming soon...
        </div>
    </div>
</div>
@endsection
