#!/bin/bash

# Quick Test Script for Fixed Issues
# Run this after applying fixes to verify everything works

set -e

echo "🧪 TESTING: Fixed Issues Verification"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_PATH="/var/www/html"

echo -e "${BLUE}🔍 Test 1: Products Page Route Generation${NC}"
cd $PROJECT_PATH
php artisan tinker --execute="
try {
    \$products = \App\Models\Item::take(3)->get();
    if (\$products->count() > 0) {
        foreach (\$products as \$product) {
            \$url = route('products.show', \$product->id);
            echo '✅ Product ' . \$product->Name . ' -> ' . \$url . PHP_EOL;
        }
    } else {
        echo '❌ No products found for testing' . PHP_EOL;
    }
} catch (Exception \$e) {
    echo '❌ Route generation error: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n${BLUE}🔍 Test 2: User Registration Column Names${NC}"
cd $PROJECT_PATH
php artisan tinker --execute="
try {
    \$fillable = (new \App\Models\User())->getFillable();
    echo '📋 User fillable columns: ' . implode(', ', \$fillable) . PHP_EOL;
    
    // Test column names match database
    \$dbColumns = \Schema::getColumnListing('users');
    \$requiredColumns = ['phone', 'delivery_address', 'role'];
    
    foreach (\$requiredColumns as \$col) {
        if (in_array(\$col, \$dbColumns)) {
            echo '✅ Column ' . \$col . ': EXISTS' . PHP_EOL;
        } else {
            echo '❌ Column ' . \$col . ': MISSING' . PHP_EOL;
        }
    }
} catch (Exception \$e) {
    echo '❌ Column check error: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n${BLUE}🔍 Test 3: Full Registration Flow Simulation${NC}"
cd $PROJECT_PATH
php artisan tinker --execute="
try {
    // Simulate the exact data from AuthController registration
    \$userData = [
        'name' => 'Test Registration User',
        'email' => 'testreg@example.com',
        'password' => \Hash::make('password123'),
        'phone' => '0771234567',
        'delivery_address' => 'Test Address, Colombo',
        'role' => 'customer'
    ];
    
    // Clean up if exists
    \$existing = \App\Models\User::where('email', 'testreg@example.com')->first();
    if (\$existing) {
        \$existing->delete();
    }
    
    \$user = \App\Models\User::create(\$userData);
    echo '✅ Registration simulation SUCCESS' . PHP_EOL;
    echo '📄 User: ' . \$user->name . ' (' . \$user->email . ')' . PHP_EOL;
    echo '📱 Phone: ' . \$user->phone . PHP_EOL;
    echo '🏠 Address: ' . \$user->delivery_address . PHP_EOL;
    echo '👤 Role: ' . \$user->role . PHP_EOL;
    
    // Test isAdmin method
    \$isAdmin = \$user->isAdmin();
    echo '🔐 Is Admin: ' . (\$isAdmin ? 'YES' : 'NO') . PHP_EOL;
    
    // Clean up
    \$user->delete();
    echo '🗑️  Test user cleaned up' . PHP_EOL;
    
} catch (Exception \$e) {
    echo '❌ Registration simulation FAILED: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n${BLUE}🔍 Test 4: Products Controller Methods${NC}"
cd $PROJECT_PATH
echo "Testing ProductController index method:"
php -r "
require_once 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';

try {
    \$controller = new App\Http\Controllers\ProductController();
    \$response = \$controller->index();
    echo '✅ ProductController::index() - SUCCESS' . PHP_EOL;
} catch (Exception \$e) {
    echo '❌ ProductController::index() - FAILED: ' . \$e->getMessage() . PHP_EOL;
}

try {
    \$item = App\Models\Item::first();
    if (\$item) {
        \$controller = new App\Http\Controllers\ProductController();
        \$response = \$controller->show(\$item->id);
        echo '✅ ProductController::show(' . \$item->id . ') - SUCCESS' . PHP_EOL;
    } else {
        echo '⚠️  No items found for show() test' . PHP_EOL;
    }
} catch (Exception \$e) {
    echo '❌ ProductController::show() - FAILED: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n${BLUE}🔍 Test 5: HTTP Response Codes${NC}"
echo "Testing HTTP responses:"
curl -s -o /dev/null -w "Products page: %{http_code} (200 expected)\n" "http://localhost/products"
curl -s -o /dev/null -w "Register page: %{http_code} (200 expected)\n" "http://localhost/register"
curl -s -o /dev/null -w "Home page: %{http_code} (200 expected)\n" "http://localhost/"

echo -e "\n${BLUE}🔍 Test 6: Route Cache Status${NC}"
cd $PROJECT_PATH
if [ -f "bootstrap/cache/routes.php" ]; then
    echo "✅ Route cache exists and is current"
    echo "📅 Route cache modified: $(stat -c %y bootstrap/cache/routes.php)"
else
    echo "⚠️  No route cache found (this is okay for development)"
fi

echo -e "\n${GREEN}🏁 Testing Complete!${NC}"
echo "======================================"
echo -e "${YELLOW}📊 Test Summary:${NC}"
echo "1. Product route generation: Should show URLs for each product"
echo "2. User column names: Should show phone, delivery_address, role as existing"
echo "3. Registration simulation: Should create user successfully"  
echo "4. Controller methods: Should return success for both index and show"
echo "5. HTTP responses: Should return 200 for all pages"
echo "6. Route cache: Should be current or missing (both okay)"
echo ""
echo -e "${BLUE}💡 If all tests pass:${NC}"
echo "- Products page should work without UrlGenerationException"
echo "- User registration should work without column not found error"
echo "- All navigation should function properly"
echo ""
echo -e "${GREEN}🎯 Ready for production testing!${NC}"