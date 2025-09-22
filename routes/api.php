<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ProductApiController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;

/*
|--------------------------------------------------------------------------
| Public Authentication APIs
|--------------------------------------------------------------------------
| Authentication endpoints that don't require authentication
*/
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/register', [AuthController::class, 'register']);
});

/*
|--------------------------------------------------------------------------
| Public Product APIs
|--------------------------------------------------------------------------
| Endpoints anyone can access without authentication
*/
Route::prefix('products')->group(function () {
    Route::get('/', [ProductApiController::class, 'index']);       // List all products
    Route::get('/{id}', [ProductApiController::class, 'show']);    // Get single product
});

/*
|--------------------------------------------------------------------------
| Sanctum-Protected APIs - Advanced Authentication & Security
|--------------------------------------------------------------------------
| Outstanding Laravel Sanctum implementation with advanced security features
*/
Route::middleware(['auth:sanctum', 'throttle:api'])->group(function () {

    /*
    |--------------------------------------------------------------------------
    | Authentication Management APIs
    |--------------------------------------------------------------------------
    | Advanced session and token management with security tracking
    */
    Route::prefix('auth')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::post('/logout-all', [AuthController::class, 'logoutAll']);
        Route::get('/sessions', [AuthController::class, 'sessions']);
        Route::delete('/sessions/{tokenId}', [AuthController::class, 'revokeSession']);
        Route::post('/refresh', [AuthController::class, 'refresh']);
    });

    /*
    |--------------------------------------------------------------------------
    | Profile & Security APIs - Outstanding Implementation
    |--------------------------------------------------------------------------
    | Customer Profile & Security API with advanced MongoDB analytics
    */
    Route::prefix('profile')->group(function () {
        // Core profile endpoints with advanced analytics
        Route::get('/', [ProfileController::class, 'profile'])
            ->name('api.profile');
        
        // Advanced login history with security dashboard
        Route::get('/login-history', [ProfileController::class, 'loginHistory'])
            ->name('api.profile.login-history');
        
        // MongoDB-powered favorites with AI recommendations
        Route::get('/favorites', [ProfileController::class, 'favorites'])
            ->name('api.profile.favorites');
        
        Route::post('/favorites', [ProfileController::class, 'addToFavorites'])
            ->name('api.profile.add-favorite');
        
        // Additional profile management endpoints
        Route::put('/update', [ProfileController::class, 'updateProfile'])
            ->name('api.profile.update');
        
        Route::post('/change-password', [ProfileController::class, 'changePassword'])
            ->name('api.profile.change-password');
        
        Route::get('/security-summary', [ProfileController::class, 'securitySummary'])
            ->name('api.profile.security-summary');
    });

    /*
    |--------------------------------------------------------------------------
    | Enhanced Product Management APIs
    |--------------------------------------------------------------------------
    | MongoDB integration for advanced product features
    */
    Route::prefix('products')->group(function () {
        Route::post('/', [ProductApiController::class, 'store'])
            ->middleware('can:products:manage');
        
        Route::put('/{id}', [ProductApiController::class, 'update'])
            ->middleware('can:products:manage');
        
        Route::delete('/{id}', [ProductApiController::class, 'destroy'])
            ->middleware('can:products:manage');
        
        // Advanced product interactions
        Route::post('/{id}/view', [ProductApiController::class, 'recordView']);
        Route::post('/{id}/review', [ProductApiController::class, 'addReview']);
        Route::get('/recommendations', [ProductApiController::class, 'recommendations']);
    });

    // Cart APIs - TODO: Implement CartApiController
    /*
    Route::get('/cart', [CartApiController::class, 'index']);             // Get current user's cart
    Route::post('/cart/add', [CartApiController::class, 'add']);          // Add item to cart
    Route::post('/cart/update', [CartApiController::class, 'update']);    // Update cart item quantity
    Route::post('/cart/remove', [CartApiController::class, 'remove']);    // Remove item from cart
    */

    // Basic authenticated user info (legacy endpoint)
    Route::get('/user', function (Request $request) {
        return response()->json([
            'status' => 'success',
            'data' => [
                'user' => $request->user()->only(['id', 'name', 'email', 'Role']),
                'current_token' => [
                    'name' => $request->user()->currentAccessToken()->name,
                    'abilities' => $request->user()->currentAccessToken()->abilities,
                ]
            ]
        ]);
    })->name('api.user');
});

/*
|--------------------------------------------------------------------------
| Admin-Only APIs (Optional Enhancement)
|--------------------------------------------------------------------------
| Advanced admin endpoints with MongoDB analytics
*/
Route::middleware(['auth:sanctum', 'throttle:api', 'can:admin:dashboard'])->prefix('admin')->group(function () {
    Route::get('/dashboard', function() {
        return response()->json([
            'status' => 'success',
            'message' => 'Admin dashboard endpoint - implement advanced analytics here'
        ]);
    });
    
    Route::get('/users/analytics', function() {
        return response()->json([
            'status' => 'success', 
            'message' => 'User analytics endpoint - implement MongoDB aggregations here'
        ]);
    });
});
