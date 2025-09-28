<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Artisan;
use App\Models\Item;
use App\Models\Product;

/*
|--------------------------------------------------------------------------
| Database Seeding Route (Remove after use)
|--------------------------------------------------------------------------
*/

Route::get('/seed-database-now', function () {
    try {
        // Only allow in production (Railway environment)
        if (config('app.env') !== 'production') {
            return 'This route only works in production environment';
        }

        // Clear existing data
        Item::truncate();
        Product::truncate();

        // Run the seeder
        Artisan::call('db:seed', ['--class' => 'ProductSeeder']);
        
        $itemCount = Item::count();
        $productCount = Product::count();
        
        return "Database seeded successfully! Created {$itemCount} items and {$productCount} products.";
        
    } catch (\Exception $e) {
        return "Error seeding database: " . $e->getMessage();
    }
})->name('seed.database');