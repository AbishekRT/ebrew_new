<div class="max-w-7xl mx-auto px-4 py-8">
    <!-- Notification -->
    <div x-data="{ 
            show: @entangle('showNotification').live,
            autoHide() {
                if (this.show) {
                    setTimeout(() => {
                        this.show = false;
                        @this.hideNotification();
                    }, 4000); // 4 seconds
                }
            }
         }" 
         x-show="show" 
         x-transition:enter="transition ease-out duration-300"
         x-transition:enter-start="opacity-0 transform translate-y-2"
         x-transition:enter-end="opacity-100 transform translate-y-0"
         x-transition:leave="transition ease-in duration-200"
         x-transition:leave-start="opacity-100 transform translate-y-0"
         x-transition:leave-end="opacity-0 transform translate-y-2"
         class="fixed top-4 right-4 z-50 bg-green-500 text-white px-6 py-4 rounded-lg shadow-lg cursor-pointer"
         x-init="$watch('show', value => { if(value) autoHide() })"
         @click="show = false; @this.hideNotification()">
        <div class="flex items-center justify-between space-x-3">
            <div class="flex items-center space-x-2">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                </svg>
                <span>{{ $notificationMessage }}</span>
            </div>
            <button @click.stop="show = false; @this.hideNotification()" class="text-white hover:text-gray-200 ml-4">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
            </button>
        </div>
    </div>

    <div class="bg-white rounded-xl shadow-lg p-6">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-3xl font-bold text-gray-800">Shopping Cart</h1>
            <div class="text-sm text-gray-600">
                {{ $cartCount }} {{ Str::plural('item', $cartCount) }}
            </div>
        </div>

        @if(count($cartItems) > 0)
            <div class="space-y-4">
                @foreach($cartItems as $cartItem)
                    <div class="flex items-center space-x-4 bg-gray-50 rounded-lg p-4" wire:key="cart-item-{{ $cartItem['id'] }}">
                        <!-- Product Image -->
                        <div class="flex-shrink-0">
                            <img src="{{ $cartItem['item']['image_url'] ?? asset('images/default.png') }}" 
                                 alt="{{ $cartItem['item']['Name'] ?? 'Product' }}" 
                                 class="w-20 h-20 object-cover rounded-lg"
                                 onerror="this.src='{{ asset('images/default.png') }}'">
                        </div>

                        <!-- Product Details -->
                        <div class="flex-grow">
                            <h3 class="text-lg font-semibold text-gray-800">{{ $cartItem['item']['Name'] ?? 'Unknown Product' }}</h3>
                            <p class="text-gray-600">${{ number_format($cartItem['item']['Price'] ?? 0, 2) }}</p>
                        </div>

                        <!-- Quantity Controls -->
                        <div class="flex items-center space-x-2">
                            <button wire:click="updateQuantity('{{ $cartItem['id'] }}', {{ $cartItem['quantity'] - 1 }})"
                                    wire:loading.attr="disabled"
                                    wire:target="updateQuantity"
                                    class="w-8 h-8 bg-gray-200 hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed rounded-full flex items-center justify-center transition">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4"></path>
                                </svg>
                            </button>
                            
                            <span class="w-12 text-center font-semibold">
                                <span wire:loading.remove wire:target="updateQuantity">{{ $cartItem['quantity'] }}</span>
                                <span wire:loading wire:target="updateQuantity" class="text-yellow-600">•••</span>
                            </span>
                            
                            <button wire:click="updateQuantity('{{ $cartItem['id'] }}', {{ $cartItem['quantity'] + 1 }})"
                                    wire:loading.attr="disabled"
                                    wire:target="updateQuantity"
                                    class="w-8 h-8 bg-gray-200 hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed rounded-full flex items-center justify-center transition">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                                </svg>
                            </button>
                        </div>

                        <!-- Subtotal -->
                        <div class="text-lg font-semibold text-gray-800 min-w-24">
                            <span wire:loading.remove wire:target="updateQuantity">
                                ${{ number_format(($cartItem['item']['Price'] ?? 0) * $cartItem['quantity'], 2) }}
                            </span>
                            <span wire:loading wire:target="updateQuantity" class="text-yellow-600">
                                $•••
                            </span>
                        </div>

                        <!-- Remove Button -->
                        <button wire:click="removeFromCart('{{ $cartItem['id'] }}')"
                                class="text-red-500 hover:text-red-700 transition"
                                wire:confirm="Are you sure you want to remove this item?">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                            </svg>
                        </button>
                    </div>
                @endforeach

                <!-- Cart Summary -->
                <div class="bg-yellow-50 rounded-lg p-6 mt-8">
                    <div class="flex justify-between items-center mb-4">
                        <span class="text-xl font-semibold text-gray-800">Total:</span>
                        <span class="text-2xl font-bold text-yellow-600">${{ number_format($cartTotal, 2) }}</span>
                    </div>
                    
                    <div class="flex space-x-4">
                        <button wire:click="clearCart" 
                                wire:confirm="Are you sure you want to clear your entire cart?"
                                class="flex-1 bg-gray-500 hover:bg-gray-600 text-white py-3 px-6 rounded-lg font-semibold transition">
                            Clear Cart
                        </button>
                        
                        <a href="{{ route('products.index') }}" 
                           class="flex-1 bg-yellow-600 hover:bg-yellow-700 text-white py-3 px-6 rounded-lg font-semibold text-center transition">
                            Continue Shopping
                        </a>
                    </div>
                </div>
            </div>
        @else
            <div class="text-center py-16">
                <svg class="mx-auto h-24 w-24 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M16 11V7a4 4 0 00-8 0v4M5 9h14a1 1 0 011 1v9a1 1 0 01-1 1H5a1 1 0 01-1-1v-9a1 1 0 011-1z"></path>
                </svg>
                <h3 class="mt-6 text-xl font-medium text-gray-900">Your cart is empty</h3>
                <p class="mt-2 text-gray-500">Start shopping to add items to your cart!</p>
                <a href="{{ route('products.index') }}" 
                   class="mt-6 inline-block bg-yellow-600 hover:bg-yellow-700 text-white px-6 py-3 rounded-lg font-semibold transition">
                    Shop Now
                </a>
            </div>
        @endif
    </div>
</div>
