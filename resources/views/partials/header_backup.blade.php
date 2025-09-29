<!-- Primary Header Navigation -->
<nav class="border-b border-gray-100 bg-white shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">

        <!-- Logo -->
        <a href="{{ route('home') }}" class="text-xl sm:text-2xl font-bold text-yellow-900 tracking-wide">eBrew</a>

        @php
            $isAdminArea = request()->is('admin*');
            $isAdmin = auth()->check() && auth()->user()->Role === 'admin';
        @endphp

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
                <a href="{{ route('products.index') }}" 
                   class="hover:text-red-600 transition">Products</a>
                <a href="{{ route('home') }}" class="hover:text-red-600 transition text-gray-500">← Back to Site</a>
            @else
                <!-- Customer Navigation -->
                <a href="{{ route('home') }}" class="hover:text-yellow-900 transition">Home</a>
                <a href="{{ route('products.index') }}" class="hover:text-yellow-900 transition">Products</a>
                <a href="{{ route('faq') }}" class="hover:text-yellow-900 transition">FAQ</a>
                @auth
                    <livewire:cart-counter />
                    <a href="{{ route('dashboard') }}" 
                       class="hover:text-yellow-900 transition {{ request()->routeIs('dashboard') ? 'text-yellow-900 font-bold border-b-2 border-yellow-900' : '' }}">Dashboard</a>
                @endauth
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
                @endif
                <span class="text-sm text-gray-600">{{ auth()->user()->name }}</span>
                <form action="{{ route('logout') }}" method="POST">
                    @csrf
                    <button class="hover:text-red-600 text-sm font-medium">Logout</button>
                </form>
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
            <a href="{{ route('home') }}" class="hover:text-red-600 text-gray-500">← Site</a>
        @else
            <!-- Customer Mobile Navigation -->
            <a href="{{ route('home') }}" class="hover:text-yellow-900">Home</a>
            <a href="{{ route('products.index') }}" class="hover:text-yellow-900 transition">Products</a>
            <a href="{{ route('faq') }}" class="hover:text-yellow-900 transition">FAQ</a>
            @auth
                <livewire:cart-counter />
                <a href="{{ route('dashboard') }}" 
                   class="hover:text-yellow-900 transition {{ request()->routeIs('dashboard') ? 'text-yellow-900 font-bold border-b-2 border-yellow-900' : '' }}">Dashboard</a>
            @endauth
        @endif
    </div>
</div>

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

@auth
<script>
function handleCartClick(event) {
    return true;
}
</script>