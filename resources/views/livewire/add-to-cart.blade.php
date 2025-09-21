<div class="space-y-4">
    <!-- Notification -->
    <div x-data="{ show: @entangle('showNotification') }" 
         x-show="show" 
         x-transition:enter="transition ease-out duration-300"
         x-transition:enter-start="opacity-0 transform translate-y-2"
         x-transition:enter-end="opacity-100 transform translate-y-0"
         x-transition:leave="transition ease-in duration-200"
         x-transition:leave-start="opacity-100 transform translate-y-0"
         x-transition:leave-end="opacity-0 transform translate-y-2"
         class="fixed top-4 right-4 z-50 bg-green-500 text-white px-6 py-4 rounded-lg shadow-lg"
         x-init="$watch('show', value => { if(value) setTimeout(() => @this.hideNotification(), 3000) })">
        <div class="flex items-center space-x-2">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            <span>{{ $notificationMessage }}</span>
        </div>
    </div>

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
            Add to Cart
        </button>
    </div>

    <!-- Product Info Summary (Optional) -->
    <div class="text-sm text-gray-600">
        <p><strong>{{ $item->Name }}</strong></p>
        <p>Rs. {{ number_format($item->Price, 2) }} each</p>
        @if($quantity > 1)
            <p class="text-gray-700 font-semibold">Total: Rs. {{ number_format($item->Price * $quantity, 2) }}</p>
        @endif
    </div>
</div>

@script
<script>
    // Auto-hide notification after 3 seconds
    $wire.on('hideNotification', () => {
        setTimeout(() => {
            @this.hideNotification();
        }, 3000);
    });
</script>
@endscript
