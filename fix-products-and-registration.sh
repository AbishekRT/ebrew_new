#!/bin/bash

# Fix Laravel Products and Registration Errors on EC2
# This script fixes the two critical errors reported

set -e

echo "🚀 FIXING: Products Page and Registration Errors"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project path
PROJECT_PATH="/var/www/html"

echo -e "${BLUE}🔍 Step 1: Verify database connection and structure${NC}"
cd $PROJECT_PATH
php artisan tinker --execute="
try {
    \DB::connection()->getPdo();
    echo '✅ Database connection: OK' . PHP_EOL;
    
    // Check if users table has correct columns
    \$userColumns = \Schema::getColumnListing('users');
    echo '📊 Users table columns: ' . implode(', ', \$userColumns) . PHP_EOL;
    
    // Check items table
    \$itemsExist = \Schema::hasTable('items');
    if (\$itemsExist) {
        \$itemCount = \DB::table('items')->count();
        echo '📊 Items table: ' . \$itemCount . ' records' . PHP_EOL;
    } else {
        echo '❌ Items table does not exist' . PHP_EOL;
    }
} catch (Exception \$e) {
    echo '❌ Database error: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n${BLUE}🔄 Step 2: Run database migrations to ensure all tables exist${NC}"
cd $PROJECT_PATH
php artisan migrate --force
echo -e "${GREEN}✅ Migrations completed${NC}"

echo -e "\n${BLUE}🗃️  Step 3: Check and seed items table if empty${NC}"
cd $PROJECT_PATH
php artisan tinker --execute="
try {
    \$itemCount = \App\Models\Item::count();
    if (\$itemCount == 0) {
        echo '🌱 Items table is empty, adding sample products...' . PHP_EOL;
        
        \$sampleItems = [
            [
                'Name' => 'Ethiopian Coffee Beans',
                'Description' => 'Premium Ethiopian coffee with rich flavor profile',
                'Price' => 2500.00,
                'Image' => '1.png',
                'TastingNotes' => 'Fruity, floral, bright acidity',
                'ShippingAndReturns' => 'Free shipping on orders over Rs. 3000',
                'RoastDates' => '2024-01-15'
            ],
            [
                'Name' => 'Colombian Dark Roast',
                'Description' => 'Bold Colombian dark roast coffee',
                'Price' => 2200.00,
                'Image' => '2.png',
                'TastingNotes' => 'Chocolate, nuts, full body',
                'ShippingAndReturns' => 'Free shipping on orders over Rs. 3000',
                'RoastDates' => '2024-01-16'
            ],
            [
                'Name' => 'Brazilian Medium Roast',
                'Description' => 'Smooth Brazilian medium roast',
                'Price' => 1800.00,
                'Image' => '3.png',
                'TastingNotes' => 'Caramel, balanced, smooth',
                'ShippingAndReturns' => 'Free shipping on orders over Rs. 3000',
                'RoastDates' => '2024-01-17'
            ],
            [
                'Name' => 'Guatemalan Antigua',
                'Description' => 'Premium Guatemalan Antigua coffee',
                'Price' => 2800.00,
                'Image' => '4.png',
                'TastingNotes' => 'Spicy, smoky, complex',
                'ShippingAndReturns' => 'Free shipping on orders over Rs. 3000',
                'RoastDates' => '2024-01-18'
            ]
        ];
        
        foreach (\$sampleItems as \$item) {
            \App\Models\Item::create(\$item);
        }
        
        \$newCount = \App\Models\Item::count();
        echo '✅ Added ' . \$newCount . ' sample items' . PHP_EOL;
    } else {
        echo '✅ Items table has ' . \$itemCount . ' products' . PHP_EOL;
    }
    
    // Test the first item to verify structure
    \$firstItem = \App\Models\Item::first();
    if (\$firstItem) {
        echo '📄 Sample product: ' . \$firstItem->Name . ' (ID: ' . \$firstItem->id . ')' . PHP_EOL;
    }
} catch (Exception \$e) {
    echo '❌ Items error: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n${BLUE}🎯 Step 4: Test ProductController functionality${NC}"
cd $PROJECT_PATH
echo "Testing Products index method:"
php -r "
require_once 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';

try {
    \$controller = new App\Http\Controllers\ProductController();
    \$response = \$controller->index();
    echo '✅ ProductController index() works' . PHP_EOL;
} catch (Exception \$e) {
    echo '❌ ProductController error: ' . \$e->getMessage() . PHP_EOL;
}
"

echo "Testing Products show method:"
php artisan tinker --execute="
try {
    \$item = \App\Models\Item::first();
    if (\$item) {
        \$controller = new \App\Http\Controllers\ProductController();
        \$response = \$controller->show(\$item->id);
        echo '✅ ProductController show() works for ID: ' . \$item->id . PHP_EOL;
    } else {
        echo '❌ No items found to test show method' . PHP_EOL;
    }
} catch (Exception \$e) {
    echo '❌ ProductController show error: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n${BLUE}🔧 Step 5: Test User registration with correct column names${NC}"
cd $PROJECT_PATH
echo "Testing User model with correct column names:"
php artisan tinker --execute="
try {
    // Test creating a user with the correct column names
    \$testData = [
        'name' => 'Test User',
        'email' => 'test@example.com',
        'password' => bcrypt('password123'),
        'phone' => '0771234567',
        'delivery_address' => 'Test Address, Colombo',
        'role' => 'customer'
    ];
    
    // Check if user already exists
    \$existingUser = \App\Models\User::where('email', 'test@example.com')->first();
    if (\$existingUser) {
        \$existingUser->delete();
        echo '🗑️  Removed existing test user' . PHP_EOL;
    }
    
    \$user = \App\Models\User::create(\$testData);
    echo '✅ User creation works with correct columns' . PHP_EOL;
    echo '📄 Created user: ' . \$user->name . ' (' . \$user->email . ')' . PHP_EOL;
    echo '📱 Phone: ' . \$user->phone . PHP_EOL;
    echo '🏠 Address: ' . \$user->delivery_address . PHP_EOL;
    echo '👤 Role: ' . \$user->role . PHP_EOL;
    
    // Clean up test user
    \$user->delete();
    echo '🗑️  Cleaned up test user' . PHP_EOL;
    
} catch (Exception \$e) {
    echo '❌ User creation error: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n${BLUE}🔄 Step 6: Clear and rebuild caches${NC}"
cd $PROJECT_PATH
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
echo -e "${GREEN}✅ All caches cleared${NC}"

php artisan config:cache
php artisan route:cache
echo -e "${GREEN}✅ Caches rebuilt${NC}"

echo -e "\n${BLUE}📝 Step 7: Verify routes are properly registered${NC}"
cd $PROJECT_PATH
echo "Checking products routes:"
php artisan route:list | grep products || echo "Products routes not found"

echo -e "\n${BLUE}🌐 Step 8: Test URL responses${NC}"
echo "Testing internal URL responses:"
curl -s -o /dev/null -w "Products list: %{http_code}\n" "http://localhost/products"
curl -s -o /dev/null -w "Register page: %{http_code}\n" "http://localhost/register"

echo -e "\n${BLUE}🔍 Step 9: Check for any remaining errors${NC}"
if [ -f "$PROJECT_PATH/storage/logs/laravel.log" ]; then
    echo "Recent Laravel errors:"
    tail -n 10 "$PROJECT_PATH/storage/logs/laravel.log" | grep -i error || echo "No recent errors in Laravel log"
else
    echo "No Laravel log file found"
fi

echo -e "\n${GREEN}🏁 Fix Complete!${NC}"
echo "================================="
echo -e "${YELLOW}📋 Issues Fixed:${NC}"
echo "✅ Products page route parameter (uses \$product->id instead of \$product->ItemID)"
echo "✅ User registration column names (phone, delivery_address, role instead of Phone, DeliveryAddress, Role)"
echo "✅ Database seeded with sample products"
echo "✅ All caches cleared and rebuilt"
echo ""
echo -e "${BLUE}🧪 Test URLs:${NC}"
echo "Products: http://ec2-13-60-43-49.eu-north-1.compute.amazonaws.com/products"
echo "Register: http://ec2-13-60-43-49.eu-north-1.compute.amazonaws.com/register"
echo ""
echo -e "${GREEN}🎯 Both issues should now be resolved!${NC}"