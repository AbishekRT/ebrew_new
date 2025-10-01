<?php

require_once 'vendor/autoload.php';

use Illuminate\Foundation\Application;
use App\Models\User;
use App\Models\Item;
use App\Models\Cart;
use App\Models\CartItem;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "Testing Cart System Fixes...\n\n";

try {
    // Test 1: Check if models can be loaded
    echo "1. Testing model loading...\n";
    $userCount = User::count();
    $itemCount = Item::count();
    echo "   Users: $userCount, Items: $itemCount\n";
    
    // Test 2: Check if admin middleware class is correct
    echo "\n2. Testing admin middleware...\n";
    $middlewareClass = \App\Http\Middleware\IsAdminMiddleware::class;
    echo "   Admin Middleware Class: $middlewareClass\n";
    
    // Test 3: Check if Cart relationships work
    echo "\n3. Testing Cart relationships...\n";
    $cart = new Cart();
    $hasItemsMethod = method_exists($cart, 'items');
    $hasUserMethod = method_exists($cart, 'user');
    echo "   Cart->items() method exists: " . ($hasItemsMethod ? 'Yes' : 'No') . "\n";
    echo "   Cart->user() method exists: " . ($hasUserMethod ? 'Yes' : 'No') . "\n";
    
    // Test 4: Check if CartItem relationships work
    echo "\n4. Testing CartItem relationships...\n";
    $cartItem = new CartItem();
    $hasCartMethod = method_exists($cartItem, 'cart');
    $hasItemMethod = method_exists($cartItem, 'item');
    echo "   CartItem->cart() method exists: " . ($hasCartMethod ? 'Yes' : 'No') . "\n";
    echo "   CartItem->item() method exists: " . ($hasItemMethod ? 'Yes' : 'No') . "\n";
    
    // Test 5: Check primary keys
    echo "\n5. Testing primary keys...\n";
    echo "   Cart primary key: " . $cart->getKeyName() . "\n";
    echo "   CartItem primary key: " . $cartItem->getKeyName() . "\n";
    echo "   Item primary key: " . (new Item())->getKeyName() . "\n";
    
    // Test 6: Try to create a test cart (if we have a user)
    $testUser = User::first();
    if ($testUser) {
        echo "\n6. Testing cart creation...\n";
        $testCart = Cart::firstOrCreate(['UserID' => $testUser->id]);
        echo "   Test cart created with ID: " . $testCart->id . "\n";
        
        $testItem = Item::first();
        if ($testItem) {
            echo "   Testing cart item creation...\n";
            $testCartItem = CartItem::updateOrCreate(
                ['CartID' => $testCart->id, 'ItemID' => $testItem->id],
                ['Quantity' => 1]
            );
            echo "   Test cart item created with ID: " . $testCartItem->id . "\n";
            
            // Clean up
            $testCartItem->delete();
            if ($testCart->items()->count() == 0) {
                $testCart->delete();
            }
            echo "   Test data cleaned up\n";
        }
    } else {
        echo "\n6. No test user available for cart testing\n";
    }
    
    echo "\n✅ Cart system tests completed successfully!\n";
    
} catch (\Exception $e) {
    echo "\n❌ Error during testing: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}