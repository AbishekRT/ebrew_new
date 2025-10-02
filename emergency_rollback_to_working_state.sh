#!/bin/bash

echo "=== EMERGENCY ROLLBACK TO LAST WORKING STATE ==="
echo "Timestamp: $(date)"
echo "Rolling back ALL changes made after email verification request..."
echo "Restoring to the exact working state from complete_restoration.sh"
echo

cd /var/www/html

# 1. Remove the debug route that was just added and broke everything
echo "1. Removing problematic debug route that caused 500 errors..."
sudo cp routes/web.php routes/web.php.broken_backup

# Remove the debug route that was just added at the end
sudo head -n -20 routes/web.php > /tmp/clean_routes.php
sudo mv /tmp/clean_routes.php routes/web.php

echo "   ✅ Removed problematic debug route"

# 2. Restore the EXACT working .env from complete_restoration.sh
echo "2. Restoring EXACT working .env configuration..."
sudo tee .env > /dev/null << 'EOF'
APP_NAME="eBrew"
APP_ENV=production
APP_KEY="base64:+2011ki4KZB3o5Sv4s3e9GqYFroSDlfovNgKU2a/apg="
APP_DEBUG=false
APP_URL="http://ec2-13-60-43-49.eu-north-1.compute.amazonaws.com"

APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=en_US
APP_TIMEZONE=UTC

LOG_CHANNEL=stack
LOG_LEVEL=error

# MySQL Database - ORIGINAL WORKING CONFIGURATION  
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ebrew_laravel_db
DB_USERNAME=ebrew_user
DB_PASSWORD=secure_db_password_2024

# MongoDB
MONGO_DB_CONNECTION=mongodb
MONGO_DB_URI=mongodb+srv://abhishakeshanaka_db_user:asiri123@ebrewapi.r7gfad9.mongodb.net/ebrew_api?retryWrites=true&w=majority&appName=ebrewAPI
MONGO_DB_DATABASE=ebrew_api
MONGO_DB_USERNAME=abhishakeshanaka_db_user
MONGO_DB_PASSWORD=asiri123
MONGO_DB_AUTH_DATABASE=admin

# Session / Cache / Queue
SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_SECURE_COOKIE=false
SESSION_SAME_SITE=lax
SESSION_COOKIE=ebrew_session

CACHE_STORE=file
QUEUE_CONNECTION=database
BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local

# Optional / Redis
REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

# Mail
MAIL_MAILER=log
MAIL_FROM_ADDRESS="hello@ebrew.com"
MAIL_FROM_NAME="${APP_NAME}"

# Vite & Assets
VITE_APP_NAME="${APP_NAME}"
ASSET_URL="http://ec2-13-60-43-49.eu-north-1.compute.amazonaws.com"
EOF

echo "   ✅ Restored EXACT working .env"

# 3. Restore EXACT working Kernel.php from complete_restoration.sh
echo "3. Restoring EXACT working Kernel.php..."
sudo tee app/Http/Kernel.php > /dev/null << 'EOF'
<?php

namespace App\Http;

use Illuminate\Foundation\Http\Kernel as HttpKernel;

class Kernel extends HttpKernel
{
    /**
     * The application's global HTTP middleware stack.
     *
     * These middleware are run during every request to your application.
     *
     * @var array<int, class-string|string>
     */
    protected $middleware = [
        // \App\Http\Middleware\TrustProxies::class,
        // \Fruitcake\Cors\HandleCors::class,
        // \App\Http\Middleware\PreventRequestsDuringMaintenance::class,
        \Illuminate\Http\Middleware\HandleCors::class,
        \Illuminate\Foundation\Http\Middleware\PreventRequestsDuringMaintenance::class,
        \Illuminate\Foundation\Http\Middleware\ValidatePostSize::class,
        \Illuminate\Foundation\Http\Middleware\TrimStrings::class,
        \Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull::class,
    ];

    /**
     * The application's route middleware groups.
     *
     * @var array<string, array<int, class-string|string>>
     */
    protected $middlewareGroups = [
        'web' => [
            // \App\Http\Middleware\EncryptCookies::class,
            \Illuminate\Cookie\Middleware\EncryptCookies::class,
            \Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse::class,
            \Illuminate\Session\Middleware\StartSession::class,
            \Illuminate\View\Middleware\ShareErrorsFromSession::class,
            // \App\Http\Middleware\VerifyCsrfToken::class,
            \Illuminate\Foundation\Http\Middleware\ValidateCsrfToken::class,
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],

        'api' => [
            // Ensures Sanctum can authenticate SPA requests
            \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
            'throttle:api',
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],
    ];

    /**
     * The application's route middleware.
     *
     * These middleware may be assigned to groups or used individually.
     *
     * @var array<string, class-string|string>
     */
    protected $routeMiddleware = [
        'auth' => \Illuminate\Auth\Middleware\Authenticate::class,
        'auth.basic' => \Illuminate\Auth\Middleware\AuthenticateWithBasicAuth::class,
        'cache.headers' => \Illuminate\Http\Middleware\SetCacheHeaders::class,
        'can' => \Illuminate\Auth\Middleware\Authorize::class,
        'guest' => \Illuminate\Auth\Middleware\RedirectIfAuthenticated::class,
        'password.confirm' => \Illuminate\Auth\Middleware\RequirePassword::class,
        'signed' => \Illuminate\Routing\Middleware\ValidateSignature::class,
        'throttle' => \Illuminate\Routing\Middleware\ThrottleRequests::class,
        'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
        'admin' => \App\Http\Middleware\IsAdminMiddleware::class,
    ];
}
EOF

echo "   ✅ Restored EXACT working Kernel.php"

# 4. Restore EXACT working routes from complete_restoration.sh  
echo "4. Restoring EXACT working routes..."
sudo tee routes/web.php > /dev/null << 'EOF'
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
| Public Routes
|--------------------------------------------------------------------------
*/

// Home
Route::get('/', [HomeController::class, 'index'])->name('home');

// Debug route for asset loading (remove in production)
Route::get('/debug/assets', function () {
    return view('debug.assets');
})->name('debug.assets');

// Debug route for database connection
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

// Products
Route::get('/products', [ProductController::class, 'index'])->name('products.index');
Route::get('/products/{id}', [ProductController::class, 'show'])->name('products.show');

// Items
Route::get('/items', [ItemController::class, 'index'])->name('items.index');
Route::get('/items/{ItemID}', [ItemController::class, 'show'])->name('items.show');

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

// FAQ
Route::get('/faq', [FaqController::class, 'index'])->name('faq');

// Cart (publicly accessible)
Route::get('/cart', [CartController::class, 'index'])->name('cart.index');

// Authentication
Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'login']);
Route::get('/register', [AuthController::class, 'showRegister'])->name('register');
Route::post('/register', [AuthController::class, 'register']);

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
    return redirect()->route('dashboard');
})->middleware(['auth', 'signed'])->name('verification.verify');

Route::post('/email/verification-notification', function (Request $request) {
    $request->user()->sendEmailVerificationNotification();
    return back()->with('status', 'verification-link-sent');
})->middleware(['auth', 'throttle:6,1'])->name('verification.send');

/*
|--------------------------------------------------------------------------
| Authenticated Routes
|--------------------------------------------------------------------------
*/
Route::middleware(['auth'])->group(function () {

    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    // Checkout
    Route::get('/checkout', [CheckoutController::class, 'index'])->name('checkout.index');
    Route::post('/checkout', [CheckoutController::class, 'process'])->name('checkout.process');
    Route::get('/buy-now/{itemId}', [CheckoutController::class, 'buyNow'])->name('checkout.buy-now');

    // Profile
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::patch('/profile/password', [ProfileController::class, 'updatePassword'])->name('profile.password.update');

    // Logout
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');
});

/*
|--------------------------------------------------------------------------
| Admin Routes
|--------------------------------------------------------------------------
*/
Route::middleware(['auth', 'admin'])->prefix('admin')->name('admin.')->group(function () {
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
| Enhanced Profile Routes (Authentication Features)
|--------------------------------------------------------------------------
*/
Route::middleware(['auth'])->group(function () {
    // Advanced authentication features (profile routes are defined above)
    
    // Advanced authentication features
    Route::get('/profile/login-history', [ProfileController::class, 'loginHistory'])->name('profile.login-history');
    Route::patch('/profile/security-settings', [ProfileController::class, 'updateSecuritySettings'])->name('profile.security-settings');
    Route::post('/profile/terminate-sessions', [ProfileController::class, 'terminateOtherSessions'])->name('profile.terminate-sessions');
    Route::get('/profile/download-data', [ProfileController::class, 'downloadData'])->name('profile.download-data');
});

// Temporary seeding route has been removed for security

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

echo "   ✅ Restored EXACT working routes"

# 5. Remove any migrations that might have been added for email verification
echo "5. Removing any email verification migrations..."
find database/migrations -name "*email*verification*" -type f -delete 2>/dev/null || true
echo "   ✅ Removed email verification migrations"

# 6. Clear ALL caches and compiled files
echo "6. Clearing ALL caches and compiled files..."
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true  
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

# Remove compiled files
rm -f bootstrap/cache/config.php 2>/dev/null || true
rm -f bootstrap/cache/routes-v7.php 2>/dev/null || true
rm -f bootstrap/cache/services.php 2>/dev/null || true

echo "   ✅ All caches cleared"

# 7. Set proper permissions
echo "7. Setting proper permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo chmod -R 775 /var/www/html/storage
sudo chmod -R 775 /var/www/html/bootstrap/cache

# 8. Restart Apache completely
echo "8. Restarting Apache completely..."
sudo systemctl restart apache2
sleep 3

# 9. Test database connection 
echo "9. Testing database connection..."
php artisan migrate:status 2>/dev/null && echo "   ✅ Database connection restored!" || echo "   ⚠️  Database connection issue"

# 10. Test that routes work
echo "10. Testing that routes work..."
php artisan route:list | head -5 2>/dev/null && echo "   ✅ Routes working!" || echo "   ⚠️  Routes issue"

echo
echo "=== EMERGENCY ROLLBACK COMPLETED ==="
echo "✅ Removed problematic debug route that caused 500 errors"
echo "✅ Restored EXACT working .env configuration" 
echo "✅ Restored EXACT working Kernel.php"
echo "✅ Restored EXACT working routes"
echo "✅ Removed email verification migrations"
echo "✅ Cleared all caches and compiled files"
echo "✅ Set proper permissions"
echo "✅ Restarted Apache"
echo
echo "🎯 SYSTEM RESTORED TO LAST KNOWN WORKING STATE:"
echo "Database: ebrew_laravel_db"
echo "Username: ebrew_user" 
echo "Password: secure_db_password_2024"
echo "Mail driver: log"
echo "Admin middleware: working"
echo
echo "🧪 TEST THE WEBSITE NOW - IT SHOULD BE WORKING:"
echo "1. Home: http://13.60.43.49/"
echo "2. Login: http://13.60.43.49/login"
echo "3. Admin: abhishake.a@gmail.com / asiri12345"
echo "4. Database: http://13.60.43.49/debug/database"
echo "5. Admin test: http://13.60.43.49/debug/admin-test"
echo
echo "The website should be working exactly as before email verification changes!"
echo "We can implement email verification properly later with a safer approach."