@extends('layouts.app')

@section('title', $product['name'] ?? 'Product - eBrew Café')

@section('content')

<main class="max-w-7xl mx-auto px-6 py-10 grid grid-cols-1 md:grid-cols-2 gap-10">

    <!-- Product Image -->
    <div class="flex justify-center items-start">
        <img src="{{ asset($product['image'] ?? 'images/default.png') }}" 
             alt="{{ $product['name'] ?? 'Product' }}" 
             class="w-full max-w-xs object-cover">
    </div>

    <!-- Product Details -->
    <div class="space-y-6">

        <!-- Name & Price -->
        <div>
            <h1 class="text-2xl font-semibold text-gray-900">
                {{ $product['name'] ?? 'Unnamed Product' }}
            </h1>
            <p class="text-lg font-medium text-gray-800 mt-1">
                Rs.{{ $product['price'] ?? '0.00' }}
            </p>
        </div>

        <!-- Description -->
        <p class="text-gray-700 leading-relaxed">
            {!! nl2br(e($product['description'] ?? 'No description available')) !!}
        </p>

        <hr class="border-gray-300">

        <!-- Extra Details -->
        <div class="space-y-4 text-sm text-gray-700">
            <div>
                <p class="font-bold">Taste Notes</p>
                <p>{!! nl2br(e($product['tastingNotes'] ?? 'N/A')) !!}</p>
            </div>

            <div>
                <p class="font-bold">Shipping and Returns</p>
                <p>{!! nl2br(e($product['shippingAndReturns'] ?? 'N/A')) !!}</p>
            </div>

            <div>
                <p class="font-bold">Roast Date</p>
                <p>{{ $product['roastDates'] ?? 'N/A' }}</p>
            </div>
        </div>

        <!-- Quantity and Buy Form -->
        <form id="add-to-cart-form" class="flex items-center space-x-4 mt-6">
            <div class="flex items-center border border-gray-300 rounded">
                <button type="button" class="px-3 py-2 text-xl font-bold text-gray-800 hover:bg-gray-100"
                        onclick="changeQuantity(-1)">−</button>
                <input type="text" name="quantity" id="quantity" value="1" readonly
                       class="w-10 text-center text-lg font-semibold border-l border-r border-gray-300">
                <button type="button" class="px-3 py-2 text-xl font-bold text-gray-800 hover:bg-gray-100"
                        onclick="changeQuantity(1)">+</button>
            </div>
            <input type="hidden" name="product_id" value="{{ $product['_id']['$oid'] ?? $product['_id'] }}">
            <button type="button" onclick="addToCart()" 
                    class="bg-[#cc0000] hover:bg-[#a30000] text-white font-semibold px-6 py-2 rounded">
                Buy Now
            </button>
        </form>

    </div>

</main>

<script>
    function changeQuantity(delta) {
        const qtyInput = document.getElementById('quantity');
        let qty = parseInt(qtyInput.value);
        qty = isNaN(qty) ? 1 : qty + delta;
        if (qty < 1) qty = 1;
        qtyInput.value = qty;
    }

    function addToCart() {
        const productId = document.querySelector('[name="product_id"]').value;
        const quantity = document.querySelector('#quantity').value;

        fetch('/api/cart/add', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': '{{ csrf_token() }}'
            },
            body: JSON.stringify({ product_id: productId, quantity: quantity })
        })
        .then(res => res.json())
        .then(data => {
            alert(data.message || 'Item added to cart!');
        })
        .catch(err => {
            console.error(err);
            alert('Error adding item to cart.');
        });
    }
</script>

@endsection
