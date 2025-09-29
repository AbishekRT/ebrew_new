#!/bin/bash

# Compare Working FAQ vs Failing Pages
# This script compares the FAQ page (working) with other pages (failing)

set -e

echo "🔍 ANALYSIS: FAQ vs Other Pages Comparison"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project path
PROJECT_PATH="/var/www/html"

echo -e "${BLUE}📋 Step 1: Route Comparison${NC}"
cd $PROJECT_PATH
echo "FAQ Route:"
php artisan route:list | grep "faq" || echo "FAQ route not found"

echo -e "\nHome Route:"
php artisan route:list | grep -E "GET.*\/\s.*home" || echo "Home route not found"

echo -e "\nProducts Route:"
php artisan route:list | grep "products" || echo "Products route not found"

echo -e "\nLogin Route:"
php artisan route:list | grep "login" || echo "Login route not found"

echo -e "\nRegister Route:"
php artisan route:list | grep "register" || echo "Register route not found"

echo -e "\n${BLUE}🎯 Step 2: Controller Method Comparison${NC}"
echo "FAQ Controller Method:"
grep -n "public function index" $PROJECT_PATH/app/Http/Controllers/FaqController.php || echo "FAQ index method not found"

echo -e "\nHome Controller Method:"
grep -n "public function index" $PROJECT_PATH/app/Http/Controllers/HomeController.php || echo "Home index method not found"

echo -e "\nProducts Controller Method:"
grep -n "public function index" $PROJECT_PATH/app/Http/Controllers/ProductController.php || echo "Products index method not found"

echo -e "\nAuth Controller Methods:"
grep -n "public function show" $PROJECT_PATH/app/Http/Controllers/AuthController.php || echo "Auth show methods not found"

echo -e "\n${BLUE}🔍 Step 3: Database Dependency Check${NC}"
echo "FAQ Controller - Database calls:"
grep -i "::.*(" $PROJECT_PATH/app/Http/Controllers/FaqController.php || echo "No database calls in FAQ"

echo -e "\nHome Controller - Database calls:"
grep -i "Item::" $PROJECT_PATH/app/Http/Controllers/HomeController.php || echo "No Item model calls in Home"

echo -e "\nProducts Controller - Database calls:"
grep -i "Item::" $PROJECT_PATH/app/Http/Controllers/ProductController.php || echo "No Item model calls in Products"

echo -e "\n${BLUE}📊 Step 4: Test Item Model Availability${NC}"
cd $PROJECT_PATH
echo "Testing Item model access:"
php artisan tinker --execute="
try {
    \$count = App\Models\Item::count();
    echo 'Items in database: ' . \$count . PHP_EOL;
} catch (Exception \$e) {
    echo 'Error accessing Item model: ' . \$e->getMessage() . PHP_EOL;
}
" || echo "Failed to test Item model"

echo -e "\n${BLUE}🌐 Step 5: Test Direct URL Access${NC}"
echo "Testing internal server responses:"

echo -e "\n${GREEN}FAQ (should work):${NC}"
curl -v -s "http://localhost/faq" 2>&1 | head -n 10 || echo "FAQ test failed"

echo -e "\n${RED}Home (currently failing):${NC}"
curl -v -s "http://localhost/" 2>&1 | head -n 10 || echo "Home test failed"

echo -e "\n${RED}Products (currently failing):${NC}"
curl -v -s "http://localhost/products" 2>&1 | head -n 10 || echo "Products test failed"

echo -e "\n${BLUE}🔧 Step 6: Test Route Generation${NC}"
cd $PROJECT_PATH
echo "Testing route URL generation:"
php artisan tinker --execute="
echo 'FAQ route: ' . route('faq') . PHP_EOL;
echo 'Home route: ' . route('home') . PHP_EOL;
echo 'Products route: ' . route('products.index') . PHP_EOL;
echo 'Login route: ' . route('login') . PHP_EOL;
echo 'Register route: ' . route('register') . PHP_EOL;
" || echo "Route generation test failed"

echo -e "\n${BLUE}📝 Step 7: View File Comparison${NC}"
echo "FAQ view file:"
ls -la $PROJECT_PATH/resources/views/faq.blade.php || echo "FAQ view not found"

echo -e "\nHome view file:"
ls -la $PROJECT_PATH/resources/views/home.blade.php || echo "Home view not found"

echo -e "\nProducts view file:"
ls -la $PROJECT_PATH/resources/views/products.blade.php || echo "Products view not found"

echo -e "\nAuth views:"
ls -la $PROJECT_PATH/resources/views/auth/ | grep -E "(login|register)" || echo "Auth views not found"

echo -e "\n${BLUE}🧪 Step 8: Test Individual Controllers${NC}"
cd $PROJECT_PATH
echo "Testing controller instantiation:"
php -r "
require_once 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';
\$kernel = \$app->make(Illuminate\Contracts\Http\Kernel::class);

// Test FAQ Controller
try {
    \$faqController = new App\Http\Controllers\FaqController();
    \$request = Illuminate\Http\Request::create('/faq', 'GET');
    \$response = \$faqController->index();
    echo '✅ FAQ Controller: Works' . PHP_EOL;
} catch (Exception \$e) {
    echo '❌ FAQ Controller Error: ' . \$e->getMessage() . PHP_EOL;
}

// Test Home Controller  
try {
    \$homeController = new App\Http\Controllers\HomeController();
    \$request = Illuminate\Http\Request::create('/', 'GET');
    \$response = \$homeController->index();
    echo '✅ Home Controller: Works' . PHP_EOL;
} catch (Exception \$e) {
    echo '❌ Home Controller Error: ' . \$e->getMessage() . PHP_EOL;
}

// Test Product Controller
try {
    \$productController = new App\Http\Controllers\ProductController();
    \$request = Illuminate\Http\Request::create('/products', 'GET');
    \$response = \$productController->index();
    echo '✅ Product Controller: Works' . PHP_EOL;
} catch (Exception \$e) {
    echo '❌ Product Controller Error: ' . \$e->getMessage() . PHP_EOL;
}
" || echo "Controller test failed"

echo -e "\n${BLUE}🔍 Step 9: Check Laravel Error Logs${NC}"
if [ -f "$PROJECT_PATH/storage/logs/laravel.log" ]; then
    echo "Last 10 lines of Laravel log:"
    tail -n 10 $PROJECT_PATH/storage/logs/laravel.log
else
    echo "No Laravel log file found"
fi

echo -e "\n${BLUE}🌐 Step 10: Check Apache Error Logs${NC}"
echo "Recent Apache errors:"
sudo tail -n 10 /var/log/apache2/error.log 2>/dev/null || echo "No Apache errors or log not accessible"

echo -e "\n${GREEN}🏁 Analysis Complete!${NC}"
echo "================================="
echo -e "${YELLOW}📋 Key Differences to Investigate:${NC}"
echo ""
echo -e "${BLUE}FAQ Controller:${NC}"
echo "- Uses static data (no database calls)"
echo "- Simple return view('faq', compact('faqs'))"
echo "- No external dependencies"
echo ""
echo -e "${BLUE}Other Controllers:${NC}"
echo "- Home: Uses Item::take(8)->get() (database call)"
echo "- Products: Uses Item::all() (database call)"  
echo "- Auth: Uses User model and Auth facade"
echo ""
echo -e "${YELLOW}💡 Hypothesis:${NC}"
echo "The issue might be related to:"
echo "1. Database connectivity for Item model"
echo "2. Model autoloading problems"
echo "3. Apache routing only working for simple controllers"
echo "4. Route caching issues with database-dependent routes"
echo ""
echo -e "${BLUE}🔧 Recommended fixes:${NC}"
echo "1. Test database connectivity"
echo "2. Clear all caches and rebuild"
echo "3. Fix Apache virtual host configuration"  
echo "4. Verify Item model and migrations"