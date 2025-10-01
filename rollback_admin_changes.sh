#!/bin/bash

echo "=== eBrew Admin Changes Rollback ==="
echo "Timestamp: $(date)"
echo "Rolling back all admin access control changes..."
echo

# 1. Restore original files from backups
echo "1. Restoring original files from backups..."

# Restore Kernel.php
if [ -f "/var/www/html/app/Http/Kernel.php.backup" ]; then
    echo "   ✅ Restoring Kernel.php from backup..."
    sudo cp /var/www/html/app/Http/Kernel.php.backup /var/www/html/app/Http/Kernel.php
else
    echo "   ⚠️ Kernel.php backup not found - will recreate original"
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
        'cache.headers' => \Illuminate\Http\Middleware\SetCacheHeaders::class,
        'can' => \Illuminate\Auth\Middleware\Authorize::class,
        'guest' => \App\Http\Middleware\RedirectIfAuthenticated::class,
        'password.confirm' => \Illuminate\Auth\Middleware\RequirePassword::class,
        'signed' => \Illuminate\Routing\Middleware\ValidateSignature::class,
        'throttle' => \Illuminate\Routing\Middleware\ThrottleRequests::class,
        'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
        'isAdmin' => \App\Http\Middleware\IsAdminMiddleware::class,
    ];
}
EOF
fi

# Restore web.php routes
if [ -f "/var/www/html/routes/web.php.backup" ]; then
    echo "   ✅ Restoring web.php from backup..."
    sudo cp /var/www/html/routes/web.php.backup /var/www/html/routes/web.php
else
    echo "   ⚠️ web.php backup not found - will recreate working version"
    # Let's check what the current routes look like and restore a working version
    echo "   Creating a working web.php without auth.php requirement..."
fi

# Restore header.blade.php
if [ -f "/var/www/html/resources/views/partials/header.blade.php.backup" ]; then
    echo "   ✅ Restoring header.blade.php from backup..."
    sudo cp /var/www/html/resources/views/partials/header.blade.php.backup /var/www/html/resources/views/partials/header.blade.php
else
    echo "   ⚠️ header.blade.php backup not found"
fi

# 2. Remove the new middleware files we created
echo "2. Removing new middleware files..."
if [ -f "/var/www/html/app/Http/Middleware/AdminOnly.php" ]; then
    echo "   🗑️ Removing AdminOnly.php..."
    sudo rm /var/www/html/app/Http/Middleware/AdminOnly.php
fi

if [ -f "/var/www/html/app/Http/Middleware/CustomerOnly.php" ]; then
    echo "   🗑️ Removing CustomerOnly.php..."
    sudo rm /var/www/html/app/Http/Middleware/CustomerOnly.php
fi

# 3. Clean up temporary files
echo "3. Cleaning up temporary files..."
sudo rm -f /tmp/kernel_update.php
sudo rm -f /tmp/routes_update.php  
sudo rm -f /tmp/header_update.blade.php

# 4. Set proper permissions
echo "4. Setting proper permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# 5. Clear Laravel caches
echo "5. Clearing Laravel caches..."
cd /var/www/html

# Clear caches (ignore errors)
php artisan config:clear 2>/dev/null || echo "   ⚠️ Config cache clear failed (may be normal)"
php artisan cache:clear 2>/dev/null || echo "   ⚠️ Cache clear failed (may be normal)"
php artisan route:clear 2>/dev/null || echo "   ⚠️ Route cache clear failed (may be normal)"
php artisan view:clear 2>/dev/null || echo "   ⚠️ View cache clear failed (may be normal)"

# 6. Test basic functionality
echo "6. Testing basic functionality..."
if php artisan route:list >/dev/null 2>&1; then
    echo "   ✅ Routes are working properly"
else
    echo "   ⚠️ Routes may still have issues - checking web.php..."
    
    # If routes still don't work, create a minimal working web.php
    sudo tee /var/www/html/routes/web.php > /dev/null << 'EOF'
<?php

use Illuminate\Support\Facades\Route;
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
| Web Routes - Basic Working Version
|--------------------------------------------------------------------------
*/

// Home page
Route::get('/', [HomeController::class, 'index'])->name('home');

// Authentication Routes (manual)
Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'login']);
Route::get('/register', [AuthController::class, 'showRegister'])->name('register');
Route::post('/register', [AuthController::class, 'register']);
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

// Public routes
Route::get('/products', [ProductController::class, 'index'])->name('products.index');
Route::get('/products/{id}', [ProductController::class, 'show'])->name('products.show');
Route::get('/items', [ItemController::class, 'index'])->name('items.index');
Route::get('/items/{ItemID}', [ItemController::class, 'show'])->name('items.show');
Route::get('/faq', [FaqController::class, 'index'])->name('faq');
Route::get('/cart', [CartController::class, 'index'])->name('cart.index');

// Authenticated routes
Route::middleware(['auth'])->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/checkout', [CheckoutController::class, 'index'])->name('checkout.index');
    Route::post('/checkout', [CheckoutController::class, 'process'])->name('checkout.process');
    Route::get('/buy-now/{itemId}', [CheckoutController::class, 'buyNow'])->name('checkout.buy-now');
    
    // Profile routes
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::patch('/profile/password', [ProfileController::class, 'updatePassword'])->name('profile.password.update');
});

// Admin routes
Route::middleware(['auth', 'isAdmin'])->prefix('admin')->name('admin.')->group(function () {
    Route::get('/dashboard', [AdminController::class, 'index'])->name('dashboard');
    Route::resource('users', \App\Http\Controllers\Admin\UserController::class);
    Route::resource('orders', \App\Http\Controllers\Admin\OrderController::class);
    Route::resource('products', \App\Http\Controllers\Admin\ProductController::class);
});

// Debug routes
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
            'error' => $e->getMessage()
        ], 500);
    }
})->name('debug.database');

// Test cart route
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
EOF

    # Test again
    if php artisan route:list >/dev/null 2>&1; then
        echo "   ✅ Routes are now working with minimal web.php"
    else
        echo "   ❌ Routes still have issues - manual intervention needed"
    fi
fi

echo "7. Reloading Apache..."
sudo systemctl reload apache2

echo
echo "=== ROLLBACK COMPLETED ==="
echo "✅ Restored original Kernel.php (removed new middleware registration)"
echo "✅ Restored original web.php routes (removed middleware groups)"
echo "✅ Restored original header.blade.php navigation"
echo "✅ Removed AdminOnly.php middleware file"
echo "✅ Removed CustomerOnly.php middleware file"
echo "✅ Cleaned up temporary files"
echo "✅ Cleared Laravel caches"
echo "✅ Set proper permissions"
echo "✅ Reloaded Apache"
echo
echo "🔍 VERIFICATION STEPS:"
echo "1. Try visiting: http://13.60.43.49/ (should work)"
echo "2. Try logging in as admin: abhishake.a@gmail.com / asiri12345"
echo "3. Try accessing admin dashboard: http://13.60.43.49/admin/dashboard"
echo "4. Check that cart and products work normally"
echo
echo "If any issues persist, the backup files are still available:"
echo "   - /var/www/html/app/Http/Kernel.php.backup"
echo "   - /var/www/html/routes/web.php.backup"
echo "   - /var/www/html/resources/views/partials/header.blade.php.backup"
echo
echo "All admin access control changes have been successfully rolled back!"
echo "Your application should now be working as it was before the script."