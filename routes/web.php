<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Foundation\Auth\EmailVerificationRequest;
use Illuminate\Http\Request;
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
Route::middleware(['auth', 'isAdmin'])->prefix('admin')->name('admin.')->group(function () {
    Route::get('/dashboard', [AdminController::class, 'index'])->name('dashboard');
    
    // User Management
    Route::resource('users', \App\Http\Controllers\Admin\UserController::class);
    
    // Order Management
    Route::resource('orders', \App\Http\Controllers\Admin\OrderController::class)->except(['create', 'store', 'edit', 'update', 'destroy']);
    
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
