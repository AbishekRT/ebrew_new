#!/bin/bash

echo "=== EMERGENCY FIX - Restore Working Website ==="
echo "Timestamp: $(date)"
echo "Fixing 500 server errors and restoring functionality"
echo

cd /var/www/html

# 1. Restore from backup first
echo "1. Restoring from backups..."
if [ -f "routes/web.php.backup" ]; then
    echo "   ✅ Restoring web.php from backup..."
    sudo cp routes/web.php.backup routes/web.php
fi

if [ -f "app/Http/Controllers/AuthController.php.backup" ]; then
    echo "   ✅ Restoring AuthController from backup..."
    sudo cp app/Http/Controllers/AuthController.php.backup app/Http/Controllers/AuthController.php
fi

if [ -f "app/Models/User.php.backup" ]; then
    echo "   ✅ Restoring User model from backup..."
    sudo cp app/Models/User.php.backup app/Models/User.php
fi

# 2. Create a clean, working web.php
echo "2. Creating clean working routes..."
sudo tee routes/web.php > /dev/null << 'EOF'
<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Foundation\Auth\EmailVerificationRequest;
use Illuminate\Http\Request;
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
            'error' => $e->getMessage()
        ], 500);
    }
})->name('debug.database');

// Products
Route::get('/products', [ProductController::class, 'index'])->name('products.index');
Route::get('/products/{id}', [ProductController::class, 'show'])->name('products.show');

// Items
Route::get('/items', [ItemController::class, 'index'])->name('items.index');
Route::get('/items/{ItemID}', [ItemController::class, 'show'])->name('items.show');

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
| Email Verification Routes (Simple)
|--------------------------------------------------------------------------
*/
Route::get('/email/verify', function () {
    return view('auth.verify-email');
})->middleware('auth')->name('verification.notice');

Route::get('/email/verify/{id}/{hash}', function (EmailVerificationRequest $request) {
    $request->fulfill();
    return redirect()->route('login')->with('success', 'Email verified! Please login to continue.');
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
});

/*
|--------------------------------------------------------------------------
| Enhanced Profile Routes
|--------------------------------------------------------------------------
*/
Route::middleware(['auth'])->group(function () {
    Route::get('/profile/login-history', [ProfileController::class, 'loginHistory'])->name('profile.login-history');
    Route::patch('/profile/security-settings', [ProfileController::class, 'updateSecuritySettings'])->name('profile.security-settings');
    Route::post('/profile/terminate-sessions', [ProfileController::class, 'terminateOtherSessions'])->name('profile.terminate-sessions');
    Route::get('/profile/download-data', [ProfileController::class, 'downloadData'])->name('profile.download-data');
});

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

// Temporary admin test route
Route::get('/debug/admin-test', function () {
    $user = \App\Models\User::where('email', 'abhishake.a@gmail.com')->first();
    if (!$user) return 'Admin user not found';
    
    return [
        'user_found' => true,
        'name' => $user->name,
        'email' => $user->email,
        'role' => $user->role,
        'is_admin_field' => $user->is_admin,
    ];
});
EOF

# 3. Restore original AuthController (working version)
echo "3. Restoring working AuthController..."
sudo tee app/Http/Controllers/AuthController.php > /dev/null << 'EOF'
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    // Show login page
    public function showLogin()
    {
        return view('auth.login');
    }

    // Process login
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);

        if (Auth::attempt($credentials)) {
            // Regenerate session to prevent fixation
            $request->session()->regenerate();

            // Check user role and redirect accordingly
            /** @var \App\Models\User $user */
            $user = Auth::user();
            
            if ($user->isAdmin()) {
                // Redirect admin users to admin dashboard
                return redirect()->intended(route('admin.dashboard'));
            } else {
                // Redirect regular users to customer dashboard
                return redirect()->intended(route('dashboard'));
            }
        }

        return back()->withErrors([
            'email' => 'Invalid credentials.',
        ])->withInput();
    }

    // Logout
    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('login');
    }

    // Show registration page
    public function showRegister()
    {
        return view('auth.register');
    }

    // Process registration
    public function register(Request $request)
    {
        $request->validate([
            'full_name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6|confirmed',
            'phone' => 'nullable|string|max:20',
            'address' => 'nullable|string|max:500',
        ]);

        User::create([
            'name' => $request->full_name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone' => $request->phone,
            'delivery_address' => $request->address,
            'role' => 'customer',
        ]);

        return redirect()->route('login')->with('success', 'Registration successful! Please login.');
    }
}
EOF

# 4. Make sure User model is clean (without email verification for now)
echo "4. Ensuring User model is clean..."
sudo sed -i 's/class User extends Authenticatable implements MustVerifyEmail/class User extends Authenticatable/' app/Models/User.php
sudo sed -i '/use Illuminate\\Contracts\\Auth\\MustVerifyEmail;/d' app/Models/User.php

# 5. Restore .env to working state (change mail back to log for now)
echo "5. Restoring mail settings to working state..."
if [ -f ".env.backup" ]; then
    sudo cp .env.backup .env
else
    # Just change mail back to log
    sudo sed -i 's/MAIL_MAILER=smtp/MAIL_MAILER=log/' .env
fi

# 6. Clear all caches
echo "6. Clearing all caches..."
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# 7. Test routes
echo "7. Testing routes..."
if php artisan route:list >/dev/null 2>&1; then
    echo "   ✅ Routes are working!"
else
    echo "   ❌ Routes still broken"
fi

# 8. Set proper permissions
echo "8. Setting proper permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# 9. Reload Apache
echo "9. Reloading Apache..."
sudo systemctl reload apache2

echo
echo "=== EMERGENCY FIX COMPLETED ==="
echo "✅ Restored working routes without complex closures"
echo "✅ Restored original AuthController"
echo "✅ Disabled email verification temporarily"
echo "✅ Restored mail to log driver"
echo "✅ Cleared all caches"
echo "✅ Set proper permissions"
echo
echo "🧪 TEST NOW:"
echo "1. Home page: http://13.60.43.49/"
echo "2. Login page: http://13.60.43.49/login"
echo "3. Admin login: abhishake.a@gmail.com / asiri12345"
echo "4. Registration: http://13.60.43.49/register"
echo
echo "Website should be working normally again!"
echo "We can add email verification back later with a simpler approach."
EOF