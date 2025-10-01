<?php

require_once 'vendor/autoload.php';

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

echo "=================================================================\n";
echo "                 CART SYSTEM DIAGNOSTIC TESTS\n";
echo "=================================================================\n\n";

use App\Models\User;
use App\Models\Item;
use App\Models\Cart;
use App\Models\CartItem;
use Illuminate\Support\Facades\DB;

try {
    echo "1. TESTING DATABASE CONNECTIONS...\n";
    echo "   MySQL Connection: ";
    $mysqlTest = DB::connection('mysql')->getPdo();
    echo "✅ Connected\n";
    
    echo "\n2. CHECKING TABLE STRUCTURES...\n";
    
    // Check items table
    $itemsCount = Item::count();
    echo "   Items table: $itemsCount records\n";
    
    if ($itemsCount > 0) {
        $firstItem = Item::first();
        echo "   First item ID: " . $firstItem->id . " (Primary key: " . $firstItem->getKeyName() . ")\n";
        echo "   First item Name: " . $firstItem->Name . "\n";
        echo "   First item Price: " . $firstItem->Price . "\n";
    }
    
    // Check carts table
    $cartsCount = Cart::count();
    echo "   Carts table: $cartsCount records\n";
    
    // Check cart_items table
    $cartItemsCount = CartItem::count();
    echo "   Cart items table: $cartItemsCount records\n";
    
    echo "\n3. TESTING MODEL RELATIONSHIPS...\n";
    
    // Test Item relationship
    if ($itemsCount > 0) {
        $testItem = Item::first();
        echo "   Testing Item->cartItems() relationship...\n";
        $cartItemsForItem = $testItem->cartItems()->count();
        echo "   Item has $cartItemsForItem cart items\n";
    }
    
    // Test creating a cart
    echo "\n4. TESTING CART CREATION...\n";
    $testUser = User::first();
    
    if ($testUser) {
        echo "   Testing with user ID: " . $testUser->id . "\n";
        
        // Create or find cart
        $cart = Cart::firstOrCreate(['UserID' => $testUser->id]);
        echo "   Cart created/found with ID: " . $cart->id . "\n";
        echo "   Cart UserID: " . $cart->UserID . "\n";
        
        // Test cart items relationship
        echo "   Cart items count: " . $cart->items()->count() . "\n";
        
        if ($itemsCount > 0) {
            $testItem = Item::first();
            echo "\n5. TESTING CART ITEM CREATION...\n";
            echo "   Adding item ID: " . $testItem->id . " to cart ID: " . $cart->id . "\n";
            
            // Try to create cart item
            try {
                $cartItem = CartItem::updateOrCreate(
                    [
                        'CartID' => $cart->id,
                        'ItemID' => $testItem->id
                    ],
                    [
                        'Quantity' => 1
                    ]
                );
                
                echo "   ✅ Cart item created with ID: " . $cartItem->id . "\n";
                echo "   Cart item CartID: " . $cartItem->CartID . "\n";
                echo "   Cart item ItemID: " . $cartItem->ItemID . "\n";
                echo "   Cart item Quantity: " . $cartItem->Quantity . "\n";
                
                // Test relationships
                echo "\n6. TESTING CART ITEM RELATIONSHIPS...\n";
                
                // Test cart item -> item relationship
                $relatedItem = $cartItem->item;
                if ($relatedItem) {
                    echo "   ✅ CartItem->item() relationship works\n";
                    echo "   Related item Name: " . $relatedItem->Name . "\n";
                    echo "   Related item Price: " . $relatedItem->Price . "\n";
                } else {
                    echo "   ❌ CartItem->item() relationship failed - item is null\n";
                }
                
                // Test cart item -> cart relationship  
                $relatedCart = $cartItem->cart;
                if ($relatedCart) {
                    echo "   ✅ CartItem->cart() relationship works\n";
                    echo "   Related cart ID: " . $relatedCart->id . "\n";
                } else {
                    echo "   ❌ CartItem->cart() relationship failed - cart is null\n";
                }
                
                // Test cart -> items relationship
                $cartItems = $cart->items;
                if ($cartItems && $cartItems->count() > 0) {
                    echo "   ✅ Cart->items() relationship works\n";
                    echo "   Cart has " . $cartItems->count() . " items\n";
                } else {
                    echo "   ❌ Cart->items() relationship failed - no items found\n";
                }
                
                // Test cart total calculation
                echo "\n7. TESTING CART CALCULATIONS...\n";
                try {
                    $cartTotal = $cart->total;
                    echo "   ✅ Cart total calculated: " . $cartTotal . "\n";
                } catch (Exception $e) {
                    echo "   ❌ Cart total calculation failed: " . $e->getMessage() . "\n";
                }
                
                try {
                    $cartItemTotal = $cartItem->total;
                    echo "   ✅ Cart item total calculated: " . $cartItemTotal . "\n";
                } catch (Exception $e) {
                    echo "   ❌ Cart item total calculation failed: " . $e->getMessage() . "\n";
                }
                
                // Clean up test data
                echo "\n8. CLEANING UP TEST DATA...\n";
                $cartItem->delete();
                if ($cart->items()->count() == 0) {
                    $cart->delete();
                }
                echo "   ✅ Test data cleaned up\n";
                
            } catch (Exception $e) {
                echo "   ❌ Cart item creation failed: " . $e->getMessage() . "\n";
                echo "   Stack trace:\n" . $e->getTraceAsString() . "\n";
            }
        }
    } else {
        echo "   ❌ No test user found for cart testing\n";
    }
    
    echo "\n=================================================================\n";
    echo "                       DIAGNOSTIC COMPLETE\n";
    echo "=================================================================\n";
    
} catch (Exception $e) {
    echo "\n❌ CRITICAL ERROR: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}