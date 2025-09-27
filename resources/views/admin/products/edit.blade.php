@extends('layouts.app')

@section('content')
<div class="min-h-screen bg-gray-50 py-6">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <!-- Header -->
        <div class="bg-white shadow rounded-lg mb-6 p-6">
            <div class="flex justify-between items-center">
                <h1 class="text-3xl font-bold text-gray-900">Edit Product: {{ $product->Name }}</h1>
                <a href="{{ route('admin.products.index') }}" class="bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded-lg transition duration-200">
                    Back to Products
                </a>
            </div>
        </div>

        @if(session('success'))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
                {{ session('success') }}
            </div>
        @endif

        @if ($errors->any())
            <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
                <ul class="list-disc list-inside">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <!-- Edit Product Form -->
        <div class="bg-white shadow rounded-lg p-6">
            <form action="{{ route('admin.products.update', $product->ItemID) }}" method="POST" enctype="multipart/form-data" class="grid grid-cols-1 md:grid-cols-2 gap-6">
                @csrf
                @method('PUT')
                
                <div class="space-y-4">
                    <div>
                        <label for="name" class="block text-sm font-medium text-gray-700">Product Name</label>
                        <input type="text" id="name" name="name" value="{{ old('name', $product->Name) }}" required
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                    </div>

                    <div>
                        <label for="price" class="block text-sm font-medium text-gray-700">Price ($)</label>
                        <input type="number" id="price" name="price" value="{{ old('price', $product->Price) }}" step="0.01" min="0" required
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                    </div>

                    <div>
                        <label for="roast_date" class="block text-sm font-medium text-gray-700">Roast Date</label>
                        <input type="date" id="roast_date" name="roast_date" 
                               value="{{ old('roast_date', $product->RoastDates ? \Carbon\Carbon::parse($product->RoastDates)->format('Y-m-d') : '') }}"
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                    </div>

                    <div>
                        <label for="image" class="block text-sm font-medium text-gray-700">Product Image</label>
                        <input type="file" id="image" name="image" accept="image/*"
                               class="mt-1 block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100">
                        <p class="mt-2 text-sm text-gray-500">Leave empty to keep current image</p>
                        
                        @if($product->Image)
                            <div class="mt-3">
                                <p class="text-sm font-medium text-gray-700 mb-2">Current Image:</p>
                                <img src="{{ $product->Image }}" alt="{{ $product->Name }}" class="h-24 w-24 object-cover rounded border">
                            </div>
                        @endif
                    </div>
                </div>

                <div class="space-y-4">
                    <div>
                        <label for="description" class="block text-sm font-medium text-gray-700">Description</label>
                        <textarea id="description" name="description" rows="4" required
                                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">{{ old('description', $product->Description) }}</textarea>
                    </div>

                    <div>
                        <label for="tasting_notes" class="block text-sm font-medium text-gray-700">Tasting Notes</label>
                        <textarea id="tasting_notes" name="tasting_notes" rows="4"
                                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">{{ old('tasting_notes', $product->TastingNotes) }}</textarea>
                    </div>

                    <div>
                        <label for="shipping_returns" class="block text-sm font-medium text-gray-700">Shipping & Returns</label>
                        <textarea id="shipping_returns" name="shipping_returns" rows="4"
                                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">{{ old('shipping_returns', $product->ShippingAndReturns) }}</textarea>
                    </div>

                    <div class="flex justify-end space-x-3">
                        <a href="{{ route('admin.products.index') }}" 
                           class="bg-gray-600 hover:bg-gray-700 text-white px-6 py-2 rounded-lg transition duration-200">
                            Cancel
                        </a>
                        <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2 rounded-lg transition duration-200">
                            Update Product
                        </button>
                    </div>
                </div>
            </form>

            <!-- Delete Product Section -->
            <div class="border-t border-gray-200 mt-8 pt-8">
                <div class="bg-red-50 border border-red-200 rounded-lg p-4">
                    <div class="flex">
                        <div class="flex-shrink-0">
                            <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                            </svg>
                        </div>
                        <div class="ml-3">
                            <h3 class="text-sm font-medium text-red-800">Danger Zone</h3>
                            <div class="mt-2 text-sm text-red-700">
                                <p>Once you delete this product, there is no going back. Please be certain.</p>
                            </div>
                            <div class="mt-4">
                                <form action="{{ route('admin.products.destroy', $product->ItemID) }}" method="POST" 
                                      onsubmit="return confirm('Are you absolutely sure you want to delete this product? This action cannot be undone.')" class="inline">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" 
                                            class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition duration-200">
                                        Delete Product
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection