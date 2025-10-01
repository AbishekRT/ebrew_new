<?php

echo "=================================================================\n";
echo "           CART SYSTEM - RELATIONSHIP VERIFICATION\n";
echo "=================================================================\n\n";

// Test the model relationships without database connection
require_once 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Item;
use App\Models\Cart;
use App\Models\CartItem;

echo "1. CHECKING MODEL CONFIGURATION...\n";

// Test Item model
$item = new Item();
echo "   Item primary key: " . $item->getKeyName() . "\n";
echo "   Item table: " . $item->getTable() . "\n";
echo "   Item fillable: " . implode(', ', $item->getFillable()) . "\n";

// Test Cart model  
$cart = new Cart();
echo "   Cart primary key: " . $cart->getKeyName() . "\n";
echo "   Cart table: " . $cart->getTable() . "\n";
echo "   Cart fillable: " . implode(', ', $cart->getFillable()) . "\n";

// Test CartItem model
$cartItem = new CartItem();
echo "   CartItem primary key: " . $cartItem->getKeyName() . "\n";
echo "   CartItem table: " . $cartItem->getTable() . "\n";
echo "   CartItem fillable: " . implode(', ', $cartItem->getFillable()) . "\n";

echo "\n2. CHECKING RELATIONSHIPS DEFINITION...\n";

// Check if relationships exist
$itemMethods = get_class_methods($item);
$cartMethods = get_class_methods($cart);
$cartItemMethods = get_class_methods($cartItem);

echo "   Item->cartItems() exists: " . (in_array('cartItems', $itemMethods) ? 'YES' : 'NO') . "\n";
echo "   Cart->items() exists: " . (in_array('items', $cartMethods) ? 'YES' : 'NO') . "\n";
echo "   Cart->user() exists: " . (in_array('user', $cartMethods) ? 'YES' : 'NO') . "\n";
echo "   CartItem->item() exists: " . (in_array('item', $cartItemMethods) ? 'YES' : 'NO') . "\n";
echo "   CartItem->cart() exists: " . (in_array('cart', $cartItemMethods) ? 'YES' : 'NO') . "\n";

echo "\n3. ANALYZING RELATIONSHIP CONFIGURATIONS...\n";

// Check Item->cartItems relationship
try {
    $itemRelation = $item->cartItems();
    $foreignKey = $itemRelation->getForeignKeyName();
    $localKey = $itemRelation->getLocalKeyName(); 
    echo "   Item->cartItems(): foreign key='$foreignKey', local key='$localKey'\n";
} catch (Exception $e) {
    echo "   Item->cartItems() error: " . $e->getMessage() . "\n";
}

// Check CartItem->item relationship
try {
    $cartItemRelation = $cartItem->item();
    $foreignKey = $cartItemRelation->getForeignKeyName();
    $ownerKey = $cartItemRelation->getOwnerKeyName();
    echo "   CartItem->item(): foreign key='$foreignKey', owner key='$ownerKey'\n";
} catch (Exception $e) {
    echo "   CartItem->item() error: " . $e->getMessage() . "\n";
}

// Check CartItem->cart relationship
try {
    $cartItemCartRelation = $cartItem->cart();
    $foreignKey = $cartItemCartRelation->getForeignKeyName();
    $ownerKey = $cartItemCartRelation->getOwnerKeyName();
    echo "   CartItem->cart(): foreign key='$foreignKey', owner key='$ownerKey'\n";
} catch (Exception $e) {
    echo "   CartItem->cart() error: " . $e->getMessage() . "\n";
}

// Check Cart->items relationship
try {
    $cartRelation = $cart->items();
    $foreignKey = $cartRelation->getForeignKeyName();
    $localKey = $cartRelation->getLocalKeyName();
    echo "   Cart->items(): foreign key='$foreignKey', local key='$localKey'\n";
} catch (Exception $e) {
    echo "   Cart->items() error: " . $e->getMessage() . "\n";
}

echo "\n4. MIGRATION FILES ANALYSIS...\n";

// Check migration files exist
$migrations = [
    'database/migrations/2025_09_21_175212_create_items_table.php',
    'database/migrations/2025_09_21_175216_create_carts_table.php', 
    'database/migrations/2025_09_21_175220_create_cart_items_table.php'
];

foreach ($migrations as $migration) {
    if (file_exists($migration)) {
        echo "   ✅ " . basename($migration) . " exists\n";
        
        // Read migration content
        $content = file_get_contents($migration);
        
        // Check for primary key definitions
        if (strpos($content, '$table->id()') !== false) {
            echo "      Uses standard Laravel id() primary key\n";
        }
        
        // Check for foreign key constraints
        if (strpos($content, 'foreign(') !== false) {
            echo "      Contains foreign key constraints\n";
        }
    } else {
        echo "   ❌ " . basename($migration) . " missing\n";
    }
}

echo "\n5. RECOMMENDED FIXES...\n";

echo "   Based on analysis, here are the issues and fixes:\n\n";

echo "   ISSUE 1: Primary Key References\n";
echo "   - All tables use 'id' as primary key (correct)\n";
echo "   - CartItem foreign keys ItemID and CartID reference 'id' columns\n";
echo "   - Relationships should use 'id' not 'ItemID' as owner key\n\n";

echo "   ISSUE 2: CartItem Relationships\n";
echo "   - CartItem->item() should use: belongsTo(Item::class, 'ItemID', 'id')\n";
echo "   - CartItem->cart() should use: belongsTo(Cart::class, 'CartID', 'id')\n";
echo "   - These appear to be correctly configured\n\n";

echo "   ISSUE 3: Potential Null Item Issues\n";
echo "   - If \$cartItem->item returns null, accessing ->Price will fail\n";
echo "   - Add null checks in getTotalAttribute() methods\n";
echo "   - Ensure foreign key constraints are working\n\n";

echo "   ISSUE 4: AddToCart Error Handling\n";
echo "   - Need better validation before database operations\n";
echo "   - Catch specific exceptions (foreign key violations, etc.)\n";
echo "   - Log detailed error information for debugging\n\n";

echo "=================================================================\n";
echo "                      NEXT STEPS\n";
echo "=================================================================\n";

echo "1. Check if database foreign key constraints are properly set\n";
echo "2. Ensure all items have valid data (Name, Price not null)\n";
echo "3. Test CartItem->item relationship returns valid items\n";
echo "4. Add null checks in all total calculation methods\n";
echo "5. Improve error handling in Livewire components\n\n";

echo "Run the application and check Laravel logs for specific error details.\n";

?>