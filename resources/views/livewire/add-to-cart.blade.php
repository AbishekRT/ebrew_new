<div class="space-y-4">
    <!-- Notification -->
    @if($showNotification)
        <div class="fixed top-20 right-4 z-40 {{ $notificationType === 'error' ? 'bg-red-500' : 'bg-green-500' }} text-white px-6 py-4 rounded-lg shadow-lg max-w-sm"
             id="cart-notification-{{ $itemId }}"
             style="animation: slideInRight 0.3s ease-out;">
            <div class="flex items-center space-x-2">
                @if($notificationType === 'error')
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                @else
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                    </svg>
                @endif
                <span class="flex-1">{{ $notificationMessage }}</span>
                <button class="ml-2 text-white hover:text-gray-200 flex-shrink-0" 
                        wire:click="hideNotification">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                    </svg>
                </button>
            </div>
        </div>
        
        <style>
            @keyframes slideInRight {
                from {
                    transform: translateX(100%);
                    opacity: 0;
                }
                to {
                    transform: translateX(0);
                    opacity: 1;
                }
            }
            
            @keyframes slideOutRight {
                from {
                    transform: translateX(0);
                    opacity: 1;
                }
                to {
                    transform: translateX(100%);
                    opacity: 0;
                }
            }
            
            .notification-hide {
                animation: slideOutRight 0.3s ease-in forwards;
            }
        </style>
        
        <script>
            // Auto-hide notification after 4 seconds
            setTimeout(function() {
                @this.hideNotification();
            }, 4000);
        </script>
    @endif

    <!-- Quantity Selector and Add to Cart Button -->
    <div class="flex items-center space-x-4">
        <!-- Quantity Selector -->
        <div class="flex items-center border border-gray-300 rounded-lg">
            <button type="button" 
                    wire:click="decrementQuantity"
                    class="px-3 py-2 text-xl font-bold text-gray-800 hover:bg-gray-100 rounded-l-lg transition">
                −
            </button>
            <div class="w-16 text-center text-lg font-semibold border-l border-r border-gray-300 py-2">
                {{ $quantity }}
            </div>
            <button type="button" 
                    wire:click="incrementQuantity"
                    class="px-3 py-2 text-xl font-bold text-gray-800 hover:bg-gray-100 rounded-r-lg transition">
                +
            </button>
        </div>

        <!-- Add to Cart Button -->
        <button type="button" 
                wire:click="addToCart"
                class="bg-[#cc0000] hover:bg-[#a30000] text-white font-semibold px-6 py-2 rounded-lg transition">
            <i class="fas fa-cart-plus mr-2"></i>Add to Cart
        </button>
        
        <!-- Buy Now Button -->
        <a href="{{ route('checkout.buy-now', $item->ItemID) }}" 
           class="bg-yellow-600 hover:bg-yellow-700 text-white font-semibold px-6 py-2 rounded-lg transition">
            <i class="fas fa-bolt mr-2"></i>Buy Now
        </a>
    </div>

    <!-- Product Info Summary (Optional) -->
    <div class="text-sm text-gray-600">
        <p>Rs. {{ number_format($item->Price, 2) }} each</p>
        @if($quantity > 1)
            <p class="text-gray-700 font-semibold">Total: Rs. {{ number_format($item->Price * $quantity, 2) }}</p>
        @endif
    </div>
</div>
