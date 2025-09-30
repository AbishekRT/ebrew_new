<!-- Primary Header Navigation -->
<nav class="border-b border-gray-100 bg-white shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">

        @php
            $isAdminArea = request()->is('admin*');
            $isAdmin = auth()->check() && auth()->user()->Role === 'admin';
        @endphp

        <!-- Logo -->
        @if($isAdminArea && $isAdmin)
            <!-- Admin Logo - Non-clickable -->
            <span class="text-xl sm:text-2xl font-bold text-red-600 tracking-wide cursor-default">eBrew</span>
        @else
            <!-- Customer Logo - Clickable -->
            <a href="{{ route('home') }}" class="text-xl sm:text-2xl font-bold text-yellow-900 tracking-wide">eBrew</a>
        @endif

        <!-- Navigation Links -->
        <div class="hidden md:flex space-x-6 text-sm font-medium text-gray-800">
            @if($isAdminArea && $isAdmin)
                <!-- Admin Navigation -->
                <a href="{{ route('admin.dashboard') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.dashboard') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Admin Dashboard</a>
                <a href="{{ route('admin.users.index') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.users.*') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Users</a>
                <a href="{{ route('admin.orders.index') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.orders.*') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Orders</a>
            @else
                <!-- Customer Navigation -->
                <a href="{{ route('home') }}" class="hover:text-yellow-900 transition">Home</a>
                <a href="{{ route('products.index') }}" class="hover:text-yellow-900 transition">Products</a>
                <a href="{{ route('faq') }}" class="hover:text-yellow-900 transition">FAQ</a>
            @endif
        </div>

        <!-- Right Side -->
        <div class="flex items-center space-x-4 text-gray-700">
            @guest
                <a href="{{ route('login') }}" class="hover:text-yellow-900 text-sm font-medium">Login</a>
                <a href="{{ route('register') }}" class="hover:text-yellow-900 text-sm font-medium">Register</a>
            @else
                @if($isAdminArea && $isAdmin)
                    <span class="text-xs bg-red-100 text-red-800 px-2 py-1 rounded-full">Admin Mode</span>
                    <span class="text-sm text-gray-600">{{ auth()->user()->name }}</span>
                    <form action="{{ route('logout') }}" method="POST">
                        @csrf
                        <button class="hover:text-red-600 text-sm font-medium">Logout</button>
                    </form>
                @else
                    <!-- Customer Profile Dropdown (moved to first position) -->
                    <div class="relative" x-data="{ open: false }">
                        <button @click="open = !open" 
                                class="hover:text-yellow-900 transition {{ request()->routeIs('dashboard') ? 'text-yellow-900' : 'text-gray-700' }}"
                                title="Profile">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                            </svg>
                        </button>
                        
                        <!-- Dropdown Menu -->
                        <div x-show="open" 
                             @click.away="open = false"
                             x-transition:enter="transition ease-out duration-200"
                             x-transition:enter-start="opacity-0 transform scale-95"
                             x-transition:enter-end="opacity-100 transform scale-100"
                             x-transition:leave="transition ease-in duration-75"
                             x-transition:leave-start="opacity-100 transform scale-100"
                             x-transition:leave-end="opacity-0 transform scale-95"
                             class="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg ring-1 ring-black ring-opacity-5 z-50">
                            <div class="py-1">
                                <a href="{{ route('dashboard') }}" 
                                   class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 hover:text-gray-900 transition">
                                    Dashboard
                                </a>
                                <form action="{{ route('logout') }}" method="POST" class="block">
                                    @csrf
                                    <button type="submit" 
                                            class="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 hover:text-red-600 transition">
                                        Logout
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>

                    <!-- Customer Cart Icon -->
                    @auth
                        <a href="{{ route('cart.index') }}" 
                           class="hover:text-yellow-900 transition relative" 
                           title="Shopping Cart">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-1.1 5a1 1 0 00.95 1.05H19M9 19v.01M20 19v.01"></path>
                            </svg>
                        </a>
                    @endauth
                @endif
            @endguest
        </div>
    </div>
</nav>

<!-- Mobile Navigation -->
<div class="md:hidden border-b border-gray-100 px-4 py-2 text-sm font-medium text-gray-700 bg-white">
    <div class="flex space-x-6 justify-center">
        @if($isAdminArea && $isAdmin)
            <!-- Admin Mobile Navigation -->
            <a href="{{ route('admin.dashboard') }}" class="hover:text-red-600">Admin Dashboard</a>
            <a href="{{ route('admin.users.index') }}" class="hover:text-red-600">Users</a>
            <a href="{{ route('admin.orders.index') }}" class="hover:text-red-600">Orders</a>
        @else
            <!-- Customer Mobile Navigation -->
            <a href="{{ route('home') }}" class="hover:text-yellow-900">Home</a>
            <a href="{{ route('products.index') }}" class="hover:text-yellow-900 transition">Products</a>
            <a href="{{ route('faq') }}" class="hover:text-yellow-900 transition">FAQ</a>
        @endif
    </div>
</div>

@auth
<script>
function handleCartClick(event) {
    return true;
}
</script>
@endauth

@guest
<script>
function handleCartClick(event) {
    event.preventDefault();
    alert('Please log in to view your cart.');
    window.location.href = '{{ route("login") }}';
    return false;
}
</script>
@endguest