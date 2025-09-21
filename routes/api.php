<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ProductApiController;
// use App\Http\Controllers\Api\CartApiController;

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
| Sanctum-Protected APIs
|--------------------------------------------------------------------------
| Only authenticated users can access these routes
*/
Route::middleware('auth:sanctum')->group(function () {

    // Cart APIs - TODO: Implement CartApiController
    /*
    Route::get('/cart', [CartApiController::class, 'index']);             // Get current user's cart
    Route::post('/cart/add', [CartApiController::class, 'add']);          // Add item to cart
    Route::post('/cart/update', [CartApiController::class, 'update']);    // Update cart item quantity
    Route::post('/cart/remove', [CartApiController::class, 'remove']);    // Remove item from cart
    */

    // Product Management APIs (optional, admin-only)
    Route::post('/products', [ProductApiController::class, 'store']);        // Create product
    Route::put('/products/{id}', [ProductApiController::class, 'update']);   // Update product
    Route::delete('/products/{id}', [ProductApiController::class, 'destroy']);// Delete product

    // Authenticated user info
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});
