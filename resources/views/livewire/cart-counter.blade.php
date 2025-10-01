<div wire:poll.5s="updateCount">
    <a href="{{ route('cart.index') }}" 
       class="hover:text-yellow-900 transition {{ request()->routeIs('cart.index') ? 'text-yellow-900 font-bold border-b-2 border-yellow-900' : '' }} relative inline-flex items-center" 
       onclick="return handleCartClick(event)">
        <!-- Shopping Cart Icon -->
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M8 11h8l1 9H7l1-9z"></path>
            <circle cx="9" cy="20" r="1"></circle>
            <circle cx="20" cy="20" r="1"></circle>
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M1 1h4l2.68 13.39a2 2 0 002 1.61h9.72"></path>
        </svg>
        @if($cartCount > 0)
            <span class="absolute -top-2 -right-2 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center animate-pulse">
                {{ $cartCount > 99 ? '99+' : $cartCount }}
            </span>
        @endif
    </a>
</div>

<script>
    // Listen for custom cart events
    window.addEventListener('cartUpdated', function() {
        @this.call('forceUpdate');
    });
    
    // Also listen for Livewire events
    Livewire.on('cartUpdated', () => {
        @this.call('forceUpdate');
    });
</script>
