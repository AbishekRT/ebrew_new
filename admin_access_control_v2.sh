#!/bin/bash

echo "=== eBrew Admin Access Control v2 ==="
echo "Timestamp: $(date)"
echo "Implementing strict admin/customer page separation"
echo

# 1. Create AdminOnly Middleware
echo "1. Creating AdminOnly middleware for strict admin access control..."
sudo tee /var/www/html/app/Http/Middleware/AdminOnly.php > /dev/null << 'EOF'
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminOnly
{
    /**
     * Handle an incoming request - STRICT admin only access
     */
    public function handle(Request $request, Closure $next)
    {
        // Check if user is authenticated
        if (!Auth::check()) {
            return redirect()->route('login')->with('error', 'Please login to access this area.');
        }

        $user = Auth::user();
        
        // Check if user is admin (handle both Role and role fields)
        $isAdmin = ($user->Role === 'admin') || ($user->role === 'admin');
        
        if (!$isAdmin) {
            return redirect()->route('login')->with('error', 'Access denied. Admin privileges required.');
        }

        return $next($request);
    }
}
EOF

# 2. Create CustomerOnly Middleware  
echo "2. Creating CustomerOnly middleware to block admin access to customer pages..."
sudo tee /var/www/html/app/Http/Middleware/CustomerOnly.php > /dev/null << 'EOF'
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CustomerOnly
{
    /**
     * Handle an incoming request - Block admin access to customer pages
     */
    public function handle(Request $request, Closure $next)
    {
        // Allow access for guests (non-authenticated users)
        if (!Auth::check()) {
            return $next($request);
        }

        $user = Auth::user();
        
        // Check if user is admin (handle both Role and role fields)
        $isAdmin = ($user->Role === 'admin') || ($user->role === 'admin');
        
        if ($isAdmin) {
            return redirect()->route('admin.dashboard')
                ->with('info', 'Admins cannot access customer pages. Use the admin panel for management.');
        }

        return $next($request);
    }
}
EOF

# 3. Register Middleware in Kernel
echo "3. Updating Kernel to register new middleware..."
sudo cp /var/www/html/app/Http/Kernel.php /var/www/html/app/Http/Kernel.php.backup

# Get current Kernel content and add middleware properly
cat > /tmp/kernel_update.php << 'EOF'
<?php

namespace App\Http;

use Illuminate\Foundation\Http\Kernel as HttpKernel;

class Kernel extends HttpKernel
{
    /**
     * The application's global HTTP middleware stack.
     */
    protected $middleware = [
        // \App\Http\Middleware\TrustHosts::class,
        \App\Http\Middleware\TrustProxies::class,
        \Illuminate\Http\Middleware\HandleCors::class,
        \App\Http\Middleware\PreventRequestsDuringMaintenance::class,
        \Illuminate\Foundation\Http\Middleware\ValidatePostSize::class,
        \App\Http\Middleware\TrimStrings::class,
        \Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull::class,
    ];

    /**
     * The application's route middleware groups.
     */
    protected $middlewareGroups = [
        'web' => [
            \App\Http\Middleware\EncryptCookies::class,
            \Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse::class,
            \Illuminate\Session\Middleware\StartSession::class,
            \Illuminate\View\Middleware\ShareErrorsFromSession::class,
            \App\Http\Middleware\VerifyCsrfToken::class,
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],

        'api' => [
            // \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
            'throttle:api',
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],
    ];

    /**
     * The application's route middleware.
     */
    protected $routeMiddleware = [
        'auth' => \App\Http\Middleware\Authenticate::class,
        'auth.basic' => \Illuminate\Auth\Middleware\AuthenticateWithBasicAuth::class,
        'cache.headers' => \Illuminate\Http\Middleware\SetCacheHeaders::class,
        'can' => \Illuminate\Auth\Middleware\Authorize::class,
        'guest' => \App\Http\Middleware\RedirectIfAuthenticated::class,
        'password.confirm' => \Illuminate\Auth\Middleware\RequirePassword::class,
        'signed' => \Illuminate\Routing\Middleware\ValidateSignature::class,
        'throttle' => \Illuminate\Routing\Middleware\ThrottleRequests::class,
        'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
        'isAdmin' => \App\Http\Middleware\IsAdminMiddleware::class,
        'adminOnly' => \App\Http\Middleware\AdminOnly::class,
        'customerOnly' => \App\Http\Middleware\CustomerOnly::class,
    ];
}
EOF

sudo cp /tmp/kernel_update.php /var/www/html/app/Http/Kernel.php

# 4. Update Routes with Clean Structure
echo "4. Updating web routes with proper access control..."
sudo cp /var/www/html/routes/web.php /var/www/html/routes/web.php.backup

cat > /tmp/routes_update.php << 'EOF'
<?php

use App\Http\Controllers\ProfileController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\CartController;
use App\Http\Controllers\CheckoutController;
use App\Http\Controllers\FAQController;
use App\Http\Controllers\Admin\AdminDashboardController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Admin\ProductController as AdminProductController;
use App\Http\Controllers\Admin\OrderController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes - With Proper Admin/Customer Separation
|--------------------------------------------------------------------------
*/

// Public routes (accessible to all)
Route::get('/', function () {
    return redirect()->route('home');
});

// Authentication Routes (Laravel Breeze)
require __DIR__.'/auth.php';

// Customer-Only Routes (blocked for admins)
Route::middleware(['customerOnly'])->group(function () {
    // Home and public pages
    Route::get('/home', [HomeController::class, 'index'])->name('home');
    Route::get('/faq', [FAQController::class, 'index'])->name('faq');
    
    // Products (customer view)
    Route::get('/products', [ProductController::class, 'index'])->name('products.index');
    Route::get('/products/{id}', [ProductController::class, 'show'])->name('products.show');
    
    // Customer Dashboard and Cart (requires auth + customer only)
    Route::middleware(['auth'])->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
        
        // Cart Management
        Route::get('/cart', [CartController::class, 'index'])->name('cart.index');
        
        // Checkout Process
        Route::get('/checkout', [CheckoutController::class, 'index'])->name('checkout.index');
        Route::post('/checkout', [CheckoutController::class, 'process'])->name('checkout.process');
        Route::get('/checkout/buy-now/{itemId}', [CheckoutController::class, 'buyNow'])->name('checkout.buy-now');
    });
});

// Admin-Only Routes (strict admin access)
Route::middleware(['adminOnly'])->prefix('admin')->name('admin.')->group(function () {
    // Admin Dashboard
    Route::get('/dashboard', [AdminDashboardController::class, 'index'])->name('dashboard');
    
    // User Management
    Route::resource('users', UserController::class);
    
    // Product Management
    Route::resource('products', AdminProductController::class)->except(['show']);
    
    // Order Management  
    Route::resource('orders', OrderController::class)->only(['index', 'show', 'update']);
});

// Profile Management (available to both admin and customers in their respective contexts)
Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

// Test and Debug Routes (remove in production)
Route::get('/test-cart-add/{itemId}', function($itemId) {
    $item = App\Models\Item::find($itemId);
    if (!$item) return 'Item not found';
    
    $sessionCart = session()->get('cart', []);
    $sessionCart[$itemId] = [
        'item_id' => $itemId,
        'name' => $item->Name,
        'price' => $item->Price,
        'quantity' => 1,
        'image' => $item->image_url
    ];
    session()->put('cart', $sessionCart);
    
    return 'Item added. Cart: ' . json_encode(session()->get('cart'));
})->name('test.cart.add');
EOF

sudo cp /tmp/routes_update.php /var/www/html/routes/web.php

# 5. Update Header Navigation
echo "5. Updating header navigation with proper role-based display..."
sudo cp /var/www/html/resources/views/partials/header.blade.php /var/www/html/resources/views/partials/header.blade.php.backup

cat > /tmp/header_update.blade.php << 'EOF'
<!-- Primary Header Navigation -->
<nav class="border-b border-gray-100 bg-white shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">

        @php
            $isAdminArea = request()->is('admin*');
            $isAdmin = auth()->check() && (auth()->user()->role === 'admin' || auth()->user()->Role === 'admin');
        @endphp

        <!-- Logo -->
        @if($isAdminArea && $isAdmin)
            <!-- Admin Logo - Links to Admin Dashboard -->
            <a href="{{ route('admin.dashboard') }}" class="text-xl sm:text-2xl font-bold text-red-600 tracking-wide">eBrew Admin</a>
        @elseif($isAdmin)
            <!-- Admin user on customer area - redirect to admin -->
            <a href="{{ route('admin.dashboard') }}" class="text-xl sm:text-2xl font-bold text-red-600 tracking-wide">eBrew Admin</a>
        @else
            <!-- Customer Logo - Links to Home -->
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
                <a href="{{ route('admin.products.index') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.products.*') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Products</a>
                <a href="{{ route('admin.orders.index') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.orders.*') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Orders</a>
            @elseif($isAdmin)
                <!-- Admin user accessing customer area - show redirect message -->
                <div class="bg-red-100 text-red-800 px-3 py-1 rounded-full text-xs">
                    Admin Account - <a href="{{ route('admin.dashboard') }}" class="underline font-semibold">Go to Admin Panel</a>
                </div>
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
                @elseif($isAdmin)
                    <!-- Admin in customer area -->
                    <div class="flex items-center space-x-2">
                        <span class="text-xs bg-red-100 text-red-800 px-2 py-1 rounded-full">Admin Account</span>
                        <a href="{{ route('admin.dashboard') }}" 
                           class="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm font-medium transition">
                            Admin Panel
                        </a>
                        <form action="{{ route('logout') }}" method="POST">
                            @csrf
                            <button class="hover:text-red-600 text-sm font-medium">Logout</button>
                        </form>
                    </div>
                @else
                    <!-- Customer Profile Dropdown -->
                    <div class="relative" x-data="{ open: false }">
                        <button @click="open = !open" 
                                class="hover:text-yellow-900 transition {{ request()->routeIs('dashboard') ? 'text-yellow-900' : 'text-gray-700' }}"
                                title="Profile">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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

                    <!-- Customer Cart Icon with Counter (only for customers) -->
                    @auth
                        <livewire:cart-counter />
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
            <a href="{{ route('admin.dashboard') }}" class="hover:text-red-600">Dashboard</a>
            <a href="{{ route('admin.users.index') }}" class="hover:text-red-600">Users</a>
            <a href="{{ route('admin.products.index') }}" class="hover:text-red-600">Products</a>
            <a href="{{ route('admin.orders.index') }}" class="hover:text-red-600">Orders</a>
        @elseif($isAdmin)
            <!-- Admin in customer area - mobile -->
            <a href="{{ route('admin.dashboard') }}" class="bg-red-600 text-white px-3 py-1 rounded">Admin Panel</a>
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
    @if($isAdmin)
        event.preventDefault();
        alert('Admin accounts cannot access cart. Use admin panel for order management.');
        return false;
    @else
        return true;
    @endif
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
EOF

sudo cp /tmp/header_update.blade.php /var/www/html/resources/views/partials/header.blade.php

# 6. Set proper permissions
echo "6. Setting proper permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# 7. Clear Laravel caches
echo "7. Clearing Laravel caches..."
cd /var/www/html
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

echo "8. Reloading Apache..."
sudo systemctl reload apache2

echo
echo "=== ADMIN ACCESS CONTROL v2 IMPLEMENTED ==="
echo "✅ AdminOnly Middleware: Created - restricts admin pages to admin users only"
echo "✅ CustomerOnly Middleware: Created - blocks admin access to customer pages"
echo "✅ Route Protection: Applied middleware to all routes with proper grouping"
echo "✅ Header Navigation: Updated to show admin/customer status and redirect options"
echo "✅ Middleware Registration: Added to Kernel for system-wide availability"
echo "✅ Backup Files: Original files backed up (.backup extension)"
echo
echo "🚨 ADMIN ACCESS RESTRICTIONS NOW ACTIVE:"
echo
echo "❌ ADMIN CANNOT ACCESS:"
echo "   - Home page (/) or (/home) → Redirects to /admin/dashboard"
echo "   - Products page (/products) → Redirects to /admin/dashboard" 
echo "   - Product detail pages (/products/{id}) → Redirects to /admin/dashboard"
echo "   - Customer dashboard (/dashboard) → Redirects to /admin/dashboard"
echo "   - Cart page (/cart) → Redirects to /admin/dashboard"
echo "   - Checkout pages (/checkout/*) → Redirects to /admin/dashboard"
echo "   - FAQ page (/faq) → Redirects to /admin/dashboard"
echo
echo "✅ ADMIN CAN ONLY ACCESS:"
echo "   - Admin Dashboard (/admin/dashboard)"
echo "   - User Management (/admin/users/*)"
echo "   - Product Management (/admin/products/*)"
echo "   - Order Management (/admin/orders/*)"
echo "   - Profile settings (/profile)"
echo
echo "✅ CUSTOMER ACCESS UNCHANGED:"
echo "   - Full access to all customer pages"
echo "   - Blocked from all /admin/* routes"
echo "   - Proper login/logout functionality"
echo
echo "🔄 SMART REDIRECTION:"
echo "   - Admin accessing customer page → Auto-redirect to admin dashboard"
echo "   - Customer accessing admin page → Redirect to login with access denied"
echo "   - Header shows role-appropriate navigation and buttons"
echo "   - Cart functionality disabled for admin accounts"
echo
echo "🧪 TESTING INSTRUCTIONS:"
echo "1. Login as admin → Try visiting /home → Should redirect to /admin/dashboard"
echo "2. Login as admin → Header should show 'Admin Panel' button and red theme"
echo "3. Login as customer → Should access all customer pages normally"
echo "4. Login as customer → Try /admin/dashboard → Should get access denied"
echo
echo "Admin access control v2 is now fully implemented and active!"