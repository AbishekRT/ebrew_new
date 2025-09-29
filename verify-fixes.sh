#!/bin/bash

# Quick Verification - Test All Fixed Issues
# Run this after the comprehensive fix to verify everything works

echo "🧪 QUICK VERIFICATION - Testing All Fixes"
echo "========================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_PATH="/var/www/html"
cd $PROJECT_PATH

echo -e "${BLUE}1. Testing Products Page Route Generation${NC}"
php artisan tinker --execute="
\$count = \App\Models\Item::count();
echo 'Items in database: ' . \$count . PHP_EOL;

if (\$count > 0) {
    \$item = \App\Models\Item::first();
    try {
        \$url = route('products.show', \$item->id);
        echo '✅ Products route works: ' . \$url . PHP_EOL;
    } catch (Exception \$e) {
        echo '❌ Products route failed: ' . \$e->getMessage() . PHP_EOL;
    }
} else {
    echo '❌ No items found' . PHP_EOL;
}
"

echo -e "\n${BLUE}2. Testing User Registration Columns${NC}"
php artisan tinker --execute="
\$columns = \Schema::getColumnListing('users');
\$required = ['phone', 'delivery_address', 'role'];

foreach (\$required as \$col) {
    if (in_array(\$col, \$columns)) {
        echo '✅ Column ' . \$col . ': EXISTS' . PHP_EOL;
    } else {
        echo '❌ Column ' . \$col . ': MISSING' . PHP_EOL;
    }
}
"

echo -e "\n${BLUE}3. Testing User Model Methods${NC}"
php artisan tinker --execute "
try {
    \$user = new \App\Models\User(['role' => 'admin']);
    echo '✅ User model isAdmin(): ' . (\$user->isAdmin() ? 'true' : 'false') . PHP_EOL;
} catch (Exception \$e) {
    echo '❌ User model error: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n${BLUE}4. Testing HTTP Responses${NC}"
curl -s -o /dev/null -w "Products: %{http_code}\n" "http://localhost/products"
curl -s -o /dev/null -w "Register: %{http_code}\n" "http://localhost/register"  
curl -s -o /dev/null -w "Login: %{http_code}\n" "http://localhost/login"

echo -e "\n${BLUE}5. Checking File Updates${NC}"
echo "AuthController updated: $(stat -c %y app/Http/Controllers/AuthController.php 2>/dev/null || echo 'Not found')"
echo "User model updated: $(stat -c %y app/Models/User.php 2>/dev/null || echo 'Not found')"
echo "Products view updated: $(stat -c %y resources/views/products.blade.php 2>/dev/null || echo 'Not found')"

echo -e "\n${GREEN}Verification Complete!${NC}"
echo "If all tests show ✅, the fixes are working correctly."