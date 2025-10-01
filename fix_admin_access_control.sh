#!/bin/bash

echo "=== eBrew Admin Access Restriction Fix ==="
echo "Timestamp: $(date)"
echo "Implementing: Proper admin access control and route restrictions"
echo

# 1. Create a new middleware for customer-only routes
echo "1. Creating CustomerOnly middleware..."
sudo tee /var/www/html/app/Http/Middleware/CustomerOnlyMiddleware.php > /dev/null << 'EOF'
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class CustomerOnlyMiddleware
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Check if user is authenticated
        if (!Auth::check()) {
            // Allow guests to access public customer pages
            return $next($request);
        }

        $user = Auth::user();
        
        // If user is admin, redirect to admin dashboard
        if ($user->isAdmin()) {
            return redirect()->route('admin.dashboard')
                ->with('info', 'Admins cannot access customer pages. Use admin dashboard for management.');
        }

        // User is a regular customer, allow access
        return $next($request);
    }
}
EOF

# 2. Update the Kernel to register the new middleware
echo "2. Updating Kernel.php to register CustomerOnly middleware..."
sudo tee /var/www/html/app/Http/Kernel.php > /dev/null << 'EOF'
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
        'auth.session' => \Illuminate\Session\Middleware\AuthenticateSession::class,
        'cache.headers' => \Illuminate\Http\Middleware\SetCacheHeaders::class,
        'can' => \Illuminate\Auth\Middleware\Authorize::class,
        'guest' => \App\Http\Middleware\RedirectIfAuthenticated::class,
        'password.confirm' => \Illuminate\Auth\Middleware\RequirePassword::class,
        'signed' => \App\Http\Middleware\ValidateSignature::class,
        'throttle' => \Illuminate\Routing\Middleware\ThrottleRequests::class,
        'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
        'admin' => \App\Http\Middleware\IsAdminMiddleware::class,
        'customer' => \App\Http\Middleware\CustomerOnlyMiddleware::class,
    ];
}
EOF

# 3. Create an enhanced admin middleware with better security
echo "3. Updating IsAdminMiddleware with enhanced security..."
sudo tee /var/www/html/app/Http/Middleware/IsAdminMiddleware.php > /dev/null << 'EOF'
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class IsAdminMiddleware
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Check if user is authenticated
        if (!Auth::check()) {
            return redirect()->route('login')
                ->with('message', 'Please login to access admin area.');
        }

        $user = Auth::user();
        
        // Check if user has admin role
        if (!$user->isAdmin()) {
            // Log unauthorized access attempt
            \Log::warning('Unauthorized admin access attempt', [
                'user_id' => $user->id,
                'user_email' => $user->email,
                'user_role' => $user->role ?? 'null',
                'requested_url' => $request->url(),
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent()
            ]);

            abort(403, 'Access denied. Admin privileges required.');
        }

        // Log successful admin access for security monitoring
        \Log::info('Admin area accessed', [
            'user_id' => $user->id,
            'user_email' => $user->email,
            'requested_url' => $request->url(),
            'ip_address' => $request->ip()
        ]);

        return $next($request);
    }
}
EOF

# 4. Update routes to use customer middleware for customer-only routes
echo "4. Updating web.php routes with proper middleware..."
sudo tee /var/www/html/routes/web.php > /dev/null << 'EOF'
<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Foundation\Auth\EmailVerificationRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\ItemController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\FaqController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\CartController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\EloquentDemoController;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\CheckoutController;

/*
|--------------------------------------------------------------------------
| Public Routes (No Authentication Required)
|--------------------------------------------------------------------------
*/

// Authentication Routes
Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'login']);
Route::get('/register', [AuthController::class, 'showRegister'])->name('register');
Route::post('/register', [AuthController::class, 'register']);

// Debug routes (REMOVE IN PRODUCTION)
Route::get('/debug/assets', function () {
    return view('debug.assets');
})->name('debug.assets');

Route::get('/debug/database', function () {
    try {
        $dbConfig = config('database.connections.mysql');
        $dbTest = DB::connection()->getPdo();
        $items = \App\Models\Item::count();
        
        return response()->json([
            'database_status' => 'Connected ✅',
            'connection_config' => [
                'host' => $dbConfig['host'],
                'port' => $dbConfig['port'],
                'database' => $dbConfig['database'],
                'username' => $dbConfig['username']
            ],
            'items_count' => $items,
            'php_version' => PHP_VERSION,
            'laravel_version' => app()->version()
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'database_status' => 'Failed ❌',
            'error' => $e->getMessage(),
            'config' => config('database.connections.mysql'),
            'env_vars' => [
                'DB_HOST' => env('DB_HOST'),
                'DB_PORT' => env('DB_PORT'),
                'DB_DATABASE' => env('DB_DATABASE'),
                'DB_USERNAME' => env('DB_USERNAME'),
                'DB_PASSWORD' => env('DB_PASSWORD') ? 'SET' : 'EMPTY'
            ]
        ], 500);
    }
})->name('debug.database');

/*
|--------------------------------------------------------------------------
| Customer-Only Routes (Blocked for Admins)
|--------------------------------------------------------------------------
*/

Route::middleware(['customer'])->group(function () {
    // Home page - customers and guests only
    Route::get('/', [HomeController::class, 'index'])->name('home');
    
    // Product browsing - customers and guests only
    Route::get('/products', [ProductController::class, 'index'])->name('products.index');
    Route::get('/products/{id}', [ProductController::class, 'show'])->name('products.show');
    
    // Items (legacy support)
    Route::get('/items', [ItemController::class, 'index'])->name('items.index');
    Route::get('/items/{ItemID}', [ItemController::class, 'show'])->name('items.show');
    
    // FAQ - customers and guests only
    Route::get('/faq', [FaqController::class, 'index'])->name('faq');
    
    // Cart - customers and guests only
    Route::get('/cart', [CartController::class, 'index'])->name('cart.index');
});

/*
|--------------------------------------------------------------------------
| Authenticated Customer Routes
|--------------------------------------------------------------------------
*/

Route::middleware(['auth', 'customer'])->group(function () {
    // Customer Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    
    // Checkout (customers only, not admins)
    Route::get('/checkout', [CheckoutController::class, 'index'])->name('checkout.index');
    Route::post('/checkout', [CheckoutController::class, 'process'])->name('checkout.process');
    Route::get('/buy-now/{itemId}', [CheckoutController::class, 'buyNow'])->name('checkout.buy-now');
    
    // Customer Profile Management
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::patch('/profile/password', [ProfileController::class, 'updatePassword'])->name('profile.password.update');
    Route::get('/profile/login-history', [ProfileController::class, 'loginHistory'])->name('profile.login-history');
    Route::patch('/profile/security-settings', [ProfileController::class, 'updateSecuritySettings'])->name('profile.security-settings');
    Route::post('/profile/terminate-sessions', [ProfileController::class, 'terminateOtherSessions'])->name('profile.terminate-sessions');
    Route::get('/profile/download-data', [ProfileController::class, 'downloadData'])->name('profile.download-data');
});

/*
|--------------------------------------------------------------------------
| General Authenticated Routes (Both Admin and Customer)
|--------------------------------------------------------------------------
*/

Route::middleware(['auth'])->group(function () {
    // Logout (available for both admins and customers)
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');
});

/*
|--------------------------------------------------------------------------
| Email Verification Routes
|--------------------------------------------------------------------------
*/
Route::get('/email/verify', function () {
    return view('auth.verify-email');
})->middleware('auth')->name('verification.notice');

Route::get('/email/verify/{id}/{hash}', function (EmailVerificationRequest $request) {
    $request->fulfill();
    
    // Redirect based on user role
    if (auth()->user()->isAdmin()) {
        return redirect()->route('admin.dashboard');
    }
    return redirect()->route('dashboard');
})->middleware(['auth', 'signed'])->name('verification.verify');

Route::post('/email/verification-notification', function (Request $request) {
    $request->user()->sendEmailVerificationNotification();
    return back()->with('status', 'verification-link-sent');
})->middleware(['auth', 'throttle:6,1'])->name('verification.send');

/*
|--------------------------------------------------------------------------
| Admin-Only Routes
|--------------------------------------------------------------------------
*/

Route::middleware(['auth', 'admin'])->prefix('admin')->name('admin.')->group(function () {
    // Admin Dashboard
    Route::get('/dashboard', [AdminController::class, 'index'])->name('dashboard');
    
    // User Management
    Route::resource('users', \App\Http\Controllers\Admin\UserController::class);
    
    // Order Management
    Route::resource('orders', \App\Http\Controllers\Admin\OrderController::class)->except(['create', 'store', 'edit', 'update', 'destroy']);
    
    // Product Management
    Route::resource('products', \App\Http\Controllers\Admin\ProductController::class)->only(['index', 'store', 'edit', 'update', 'destroy']);
    
    // Security Dashboard
    Route::get('/security', [\App\Http\Controllers\Admin\SecurityDashboardController::class, 'index'])->name('security.dashboard');
    Route::get('/security/users/{user}', [\App\Http\Controllers\Admin\SecurityDashboardController::class, 'userHistory'])->name('security.user-history');
    Route::post('/security/force-logout/{user}', [\App\Http\Controllers\Admin\SecurityDashboardController::class, 'forceLogout'])->name('security.force-logout');
    Route::post('/security/block-ip', [\App\Http\Controllers\Admin\SecurityDashboardController::class, 'blockIp'])->name('security.block-ip');
    Route::get('/security/export', [\App\Http\Controllers\Admin\SecurityDashboardController::class, 'exportReport'])->name('security.export');
    
    // Advanced Eloquent Demonstration Routes (Admin Only)
    Route::prefix('eloquent-demo')->name('eloquent-demo.')->group(function () {
        Route::get('/scopes', [EloquentDemoController::class, 'advancedScopes'])->name('scopes');
        Route::get('/polymorphic', [EloquentDemoController::class, 'polymorphicRelationships'])->name('polymorphic');
        Route::get('/relationships', [EloquentDemoController::class, 'advancedRelationships'])->name('relationships');
        Route::get('/mutators', [EloquentDemoController::class, 'mutatorsCastsAccessors'])->name('mutators');
        Route::get('/service-layer', [EloquentDemoController::class, 'serviceLayerDemo'])->name('service-layer');
        Route::get('/collections', [EloquentDemoController::class, 'customCollections'])->name('collections');
        Route::get('/complex-queries', [EloquentDemoController::class, 'complexQueries'])->name('complex-queries');
        Route::get('/performance', [EloquentDemoController::class, 'performanceOptimizations'])->name('performance');
    });
});

/*
|--------------------------------------------------------------------------
| Test and Debug Routes (REMOVE IN PRODUCTION)
|--------------------------------------------------------------------------
*/

// Test route for cart debugging
Route::get('/test-cart-add/{itemId}', function($itemId) {
    $item = App\Models\Item::where('ItemID', $itemId)->first();
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
});

// Temporary admin test route (REMOVE IN PRODUCTION)
Route::get('/debug/admin-test', function () {
    $user = \App\Models\User::where('email', 'abhishake.a@gmail.com')->first();
    if (!$user) return 'Admin user not found';
    
    return [
        'user_found' => true,
        'name' => $user->name,
        'email' => $user->email,
        'role' => $user->role,
        'is_admin_field' => $user->is_admin,
        'isAdmin_method' => $user->isAdmin(),
        'password_test_asiri12345' => \Hash::check('asiri12345', $user->password),
        'can_manually_login' => \Auth::loginUsingId($user->id) ? 'Success' : 'Failed',
        'now_authenticated' => \Auth::check() ? 'Yes - User: ' . \Auth::user()->email : 'No'
    ];
});

// Debug routes (REMOVE IN PRODUCTION)
if (app()->environment(['local', 'staging']) || env('APP_DEBUG')) {
    require __DIR__.'/debug.php';
}
EOF

# 5. Update header to show appropriate navigation based on user role
echo "5. Updating header with role-based navigation..."
sudo tee /var/www/html/resources/views/partials/header.blade.php > /dev/null << 'EOF'
<!-- Primary Header Navigation -->
<nav class="border-b border-gray-100 bg-white shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">

        @php
            $isAdminArea = request()->is('admin*');
            $isAdmin = auth()->check() && auth()->user()->isAdmin();
        @endphp

        <!-- Logo -->
        @if($isAdmin)
            @if($isAdminArea)
                <!-- Admin Area - Non-clickable logo -->
                <span class="text-xl sm:text-2xl font-bold text-red-600 tracking-wide cursor-default">eBrew Admin</span>
            @else
                <!-- Admin not in admin area - redirect to admin dashboard -->
                <a href="{{ route('admin.dashboard') }}" class="text-xl sm:text-2xl font-bold text-red-600 tracking-wide">eBrew Admin</a>
            @endif
        @else
            <!-- Customer Logo - Clickable -->
            <a href="{{ route('home') }}" class="text-xl sm:text-2xl font-bold text-yellow-900 tracking-wide">eBrew</a>
        @endif

        <!-- Navigation Links -->
        <div class="hidden md:flex space-x-6 text-sm font-medium text-gray-800">
            @if($isAdmin)
                <!-- Admin Navigation - Only show admin links -->
                <a href="{{ route('admin.dashboard') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.dashboard') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Dashboard</a>
                <a href="{{ route('admin.users.index') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.users.*') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Users</a>
                <a href="{{ route('admin.orders.index') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.orders.*') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Orders</a>
                <a href="{{ route('admin.products.index') }}" 
                   class="hover:text-red-600 transition {{ request()->routeIs('admin.products.*') ? 'text-red-600 font-bold border-b-2 border-red-600' : '' }}">Products</a>
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
                @if($isAdmin)
                    <!-- Admin User Display -->
                    <span class="text-xs bg-red-100 text-red-800 px-2 py-1 rounded-full">Admin</span>
                    <span class="text-sm text-gray-600">{{ auth()->user()->name }}</span>
                    <form action="{{ route('logout') }}" method="POST" class="inline">
                        @csrf
                        <button class="hover:text-red-600 text-sm font-medium transition">Logout</button>
                    </form>
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

                    <!-- Customer Cart Icon with Counter -->
                    <livewire:cart-counter />
                @endif
            @endguest
        </div>
    </div>
</nav>

<!-- Mobile Navigation -->
<div class="md:hidden border-b border-gray-100 px-4 py-2 text-sm font-medium text-gray-700 bg-white">
    <div class="flex space-x-6 justify-center">
        @if($isAdmin)
            <!-- Admin Mobile Navigation -->
            <a href="{{ route('admin.dashboard') }}" class="hover:text-red-600">Dashboard</a>
            <a href="{{ route('admin.users.index') }}" class="hover:text-red-600">Users</a>
            <a href="{{ route('admin.orders.index') }}" class="hover:text-red-600">Orders</a>
            <a href="{{ route('admin.products.index') }}" class="hover:text-red-600">Products</a>
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
    @if(auth()->user()->isAdmin())
        // Admins shouldn't access cart
        event.preventDefault();
        alert('Admin accounts cannot access shopping cart. Use admin dashboard for management.');
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

# 6. Create a redirect controller for role-based routing after login
echo "6. Updating AuthController with role-based redirects..."
sudo tee /var/www/html/app/Http/Controllers/AuthController.php > /dev/null << 'EOF'
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use App\Models\User;

class AuthController extends Controller
{
    public function showLogin()
    {
        return view('auth.login');
    }

    public function showRegister()
    {
        return view('auth.register');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);

        if (Auth::attempt($credentials, $request->filled('remember'))) {
            $request->session()->regenerate();
            
            $user = Auth::user();
            
            // Log successful login
            \Log::info('User login successful', [
                'user_id' => $user->id,
                'email' => $user->email,
                'role' => $user->role ?? 'customer',
                'is_admin' => $user->isAdmin(),
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent()
            ]);
            
            // Role-based redirect
            if ($user->isAdmin()) {
                return redirect()->intended(route('admin.dashboard'))
                    ->with('success', 'Welcome back, ' . $user->name . '! Admin dashboard loaded.');
            } else {
                return redirect()->intended(route('dashboard'))
                    ->with('success', 'Welcome back, ' . $user->name . '!');
            }
        }

        // Log failed login attempt
        \Log::warning('Failed login attempt', [
            'email' => $request->email,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent()
        ]);

        return back()->withErrors([
            'email' => 'The provided credentials do not match our records.',
        ])->onlyInput('email');
    }

    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => 'customer', // Default role for new registrations
        ]);

        // Log new user registration
        \Log::info('New user registered', [
            'user_id' => $user->id,
            'email' => $user->email,
            'name' => $user->name,
            'ip_address' => $request->ip()
        ]);

        Auth::login($user);

        return redirect()->route('dashboard')
            ->with('success', 'Registration successful! Welcome to eBrew, ' . $user->name . '!');
    }

    public function logout(Request $request)
    {
        $user = Auth::user();
        
        // Log logout
        \Log::info('User logout', [
            'user_id' => $user->id,
            'email' => $user->email,
            'ip_address' => $request->ip()
        ]);

        Auth::logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login')
            ->with('success', 'You have been logged out successfully.');
    }
}
EOF

echo "7. Setting proper permissions and clearing caches..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

cd /var/www/html
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

echo "8. Reloading Apache..."
sudo systemctl reload apache2

echo
echo "=== ADMIN ACCESS RESTRICTION IMPLEMENTED ==="
echo "✅ CustomerOnly Middleware: Created middleware to block admin access to customer pages"
echo "✅ Route Protection: All customer pages now protected with 'customer' middleware"
echo "✅ Admin Isolation: Admins can only access admin/* routes and dashboard"
echo "✅ Role-based Navigation: Header shows appropriate navigation based on user role"
echo "✅ Enhanced Security: Comprehensive logging of access attempts and role checks"
echo "✅ Automatic Redirects: Admins automatically redirected to admin dashboard"
echo
echo "🚫 BLOCKED PAGES FOR ADMINS:"
echo "   - Home page (/) -> Redirects to admin dashboard"
echo "   - Products (/products) -> Redirects to admin dashboard"  
echo "   - FAQ (/faq) -> Redirects to admin dashboard"
echo "   - Cart (/cart) -> Redirects to admin dashboard"
echo "   - Product details (/products/{id}) -> Redirects to admin dashboard"
echo "   - Customer dashboard (/dashboard) -> Redirects to admin dashboard"
echo "   - Checkout pages (/checkout) -> Redirects to admin dashboard"
echo "   - Customer profile (/profile) -> Redirects to admin dashboard"
echo
echo "✅ ALLOWED PAGES FOR ADMINS:"
echo "   - Admin Dashboard (/admin/dashboard)"
echo "   - User Management (/admin/users)"
echo "   - Order Management (/admin/orders)"
echo "   - Product Management (/admin/products)"
echo "   - Security Dashboard (/admin/security)"
echo
echo "🔍 TEST VERIFICATION:"
echo "1. Login as admin (abhishake.a@gmail.com)"
echo "2. Try to visit http://13.60.43.49/ - should redirect to admin dashboard"
echo "3. Try to visit http://13.60.43.49/products - should redirect to admin dashboard"  
echo "4. Navigation header should only show admin links"
echo "5. Logo should show 'eBrew Admin' and redirect to admin dashboard"
echo
echo "Complete role separation implemented with security logging!"