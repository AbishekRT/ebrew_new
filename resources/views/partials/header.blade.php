<!-- Primary Header Navigation -->
<nav class="border-b border-gray-100 bg-white shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        @php
            $isAdmin = auth()->check() && auth()->user()->role === 'admin';
        @endphp

        <!-- Logo -->
        @if ($isAdmin)
            <span class="text-xl sm:text-2xl font-bold text-yellow-900 tracking-wide">eBrew</span>
        @else
            <a href="{{ route('home') }}" class="text-xl sm:text-2xl font-bold text-yellow-900 tracking-wide">eBrew</a>
        @endif

        <!-- Navigation Links (Customer only) -->
        @if (! $isAdmin)
             <div class="hidden md:flex space-x-6 text-sm font-medium text-gray-800">
                 <a href="{{ route('home') }}" class="hover:text-yellow-900 transition">Home</a>
                <a href="{{ route('products.index') }}" class="hover:text-yellow-900 transition">Products</a>
                <a href="{{ route('faq') }}" class="hover:text-yellow-900 transition">FAQ</a>
            </div>
        @endif


        <!-- Right Side -->
        <div class="flex items-center space-x-4 text-gray-700">
            @guest
                <a href="{{ route('login') }}" class="hover:text-yellow-900 text-sm font-medium">Login</a>
                <a href="{{ route('register') }}" class="hover:text-yellow-900 text-sm font-medium">Register</a>
            @else
                <form action="{{ route('logout') }}" method="POST">
                    @csrf
                    <button class="hover:text-yellow-900 text-sm font-medium">Logout</button>
                </form>
                @if (! $isAdmin)
                    <a href="{{ route('cart.index') }}" class="text-xl hover:text-yellow-900">
                        <i class="fas fa-shopping-cart"></i>
                    </a>
                @endif
                <a href="{{ $isAdmin ? '#' : route('home') }}" class="text-xl hover:text-yellow-900">
                    <i class="fas fa-user-circle"></i>
                </a>
            @endguest
        </div>
    </div>
</nav>

<!-- Optional Mobile Nav -->
@if (! $isAdmin)
<div class="md:hidden border-b border-gray-100 px-4 py-2 text-sm font-medium text-gray-700 bg-white">
    <div class="flex space-x-6 justify-center">
        <a href="{{ route('home') }}" class="hover:text-yellow-900">Home</a>
                <a href="{{ route('products.index') }}" class="hover:text-yellow-900 transition">Products</a>
                <a href="{{ route('faq') }}" class="hover:text-yellow-900 transition">FAQ</a>
            </div>
</div>
@endif
