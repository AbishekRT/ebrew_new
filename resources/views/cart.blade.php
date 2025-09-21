@extends('layouts.app')

@section('title', 'Your Cart - eBrew Café')

@section('content')

<div class="max-w-7xl mx-auto px-4 py-12">
    <h2 class="text-3xl font-bold mb-8">Your Cart</h2>

    <div id="cart-container">
        <!-- Cart will be dynamically loaded here -->
        <p class="text-gray-500">Loading cart...</p>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', () => {
    const cartContainer = document.getElementById('cart-container');

    // Fetch cart items from API
    async function fetchCart() {
        try {
            const res = await fetch('/api/cart', {
                headers: {
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                }
            });
            const data = await res.json();
            renderCart(data);
        } catch (err) {
            console.error(err);
            cartContainer.innerHTML = "<p class='text-red-600'>Error loading cart.</p>";
        }
    }

    // Render cart HTML
    function renderCart(cart) {
        if (!cart.items || cart.items.length === 0) {
            cartContainer.innerHTML = `
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
            `;
            return;
        }

        let subtotal = 0;
        cart.items.forEach(item => subtotal += item.price * item.quantity);

        let cartItemsHtml = cart.items.map(item => `
            <div class="flex flex-col md:flex-row items-center justify-between border rounded-lg p-4 shadow-sm mb-4">
                <!-- Image + Name -->
                <div class="flex items-center gap-4 w-full md:w-1/3 mb-4 md:mb-0">
                    <img src="${item.image}" alt="${item.name}" class="w-16 h-16 object-cover border rounded">
                    <p class="font-semibold">${item.name}</p>
                </div>

                <!-- Price -->
                <p class="font-bold text-xl text-center w-full md:w-1/3 mb-4 md:mb-0">
                    Rs.${item.price.toFixed(2)}
                </p>

                <!-- Qty controls + Delete -->
                <div class="flex justify-center md:justify-end items-center space-x-2 w-full md:w-1/3">
                    <button onclick="updateCart('${item.product_id}', 'decrement')" 
                            class="px-3 py-1 rounded bg-gray-200 hover:bg-gray-300 text-lg" ${item.quantity <= 1 ? 'disabled' : ''}>−</button>
                    <span class="px-3">${item.quantity}</span>
                    <button onclick="updateCart('${item.product_id}', 'increment')" 
                            class="px-3 py-1 rounded bg-gray-200 hover:bg-gray-300 text-lg">+</button>
                    <button onclick="removeItem('${item.product_id}')" 
                            class="p-2 rounded-full bg-red-100 hover:bg-red-200 text-red-600 transition" title="Remove Item">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24"
                            stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
            </div>
        `).join('');

        // Summary box
        let summaryHtml = `
            <div class="bg-gray-100 p-6 rounded-lg shadow-md h-fit">
                <h3 class="text-xl font-semibold mb-4">
                    Summary (${cart.items.length} item${cart.items.length > 1 ? 's' : ''})
                </h3>
                <div class="flex justify-between mb-2 text-sm"><span>Subtotal</span><span>Rs.${subtotal.toFixed(2)}</span></div>
                <div class="flex justify-between mb-2 text-sm"><span>Shipping</span><span>–</span></div>
                <div class="flex justify-between mb-4 text-sm"><span>Est. Taxes</span><span>–</span></div>
                <hr class="border-gray-300 mb-4">
                <div class="flex justify-between font-bold text-lg mb-6"><span>Total</span><span>Rs.${subtotal.toFixed(2)}</span></div>
                <a href="{{ url('/checkout') }}" class="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 rounded font-semibold text-center block">
                    Checkout
                </a>
            </div>
        `;

        cartContainer.innerHTML = `
            <div class="grid lg:grid-cols-3 gap-8">
                <div class="lg:col-span-2 space-y-6">
                    ${cartItemsHtml}
                </div>
                ${summaryHtml}
            </div>
        `;
    }

    // Update quantity
    async function updateCart(productId, action) {
        try {
            const res = await fetch('/api/cart/update', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                },
                body: JSON.stringify({ product_id: productId, action: action })
            });
            const data = await res.json();
            alert(data.message || 'Cart updated');
            fetchCart(); // Refresh cart
        } catch (err) {
            console.error(err);
            alert('Error updating cart');
        }
    }

    // Remove item
    async function removeItem(productId) {
        if (!confirm('Are you sure you want to remove this item?')) return;
        try {
            const res = await fetch('/api/cart/remove', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                },
                body: JSON.stringify({ product_id: productId })
            });
            const data = await res.json();
            alert(data.message || 'Item removed');
            fetchCart(); // Refresh cart
        } catch (err) {
            console.error(err);
            alert('Error removing item');
        }
    }

    // Initial load
    fetchCart();
});
</script>

@endsection
