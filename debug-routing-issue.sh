#!/bin/bash

# Debug Laravel Routing Issues on EC2
# This script will help identify why only FAQ page works while other routes fail

set -e

echo "🔍 DEBUG: Laravel Routing Issue Analysis"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project path
PROJECT_PATH="/var/www/html"

echo -e "${BLUE}📍 Current working directory:${NC}"
pwd

echo -e "\n${BLUE}📂 Checking project structure...${NC}"
ls -la $PROJECT_PATH/

echo -e "\n${BLUE}🔧 PHP and Laravel versions:${NC}"
php -v | head -n 1
cd $PROJECT_PATH && php artisan --version

echo -e "\n${BLUE}📋 Checking Laravel route cache:${NC}"
cd $PROJECT_PATH
if [ -f "bootstrap/cache/routes.php" ]; then
    echo -e "${YELLOW}⚠️  Route cache exists. Let's clear it:${NC}"
    php artisan route:clear
    echo -e "${GREEN}✅ Route cache cleared${NC}"
else
    echo -e "${GREEN}✅ No route cache found${NC}"
fi

echo -e "\n${BLUE}📝 Checking all registered routes:${NC}"
cd $PROJECT_PATH
php artisan route:list --columns=Method,URI,Name,Action | head -n 20

echo -e "\n${BLUE}🎯 Testing specific routes we need:${NC}"
echo "Looking for these routes:"
php artisan route:list | grep -E "(GET.*\/.*home|GET.*\/.*products|GET.*\/.*faq|GET.*\/.*login|GET.*\/.*register)" || echo "Some routes might be missing!"

echo -e "\n${BLUE}🔍 Checking controller files:${NC}"
ls -la $PROJECT_PATH/app/Http/Controllers/ | grep -E "(HomeController|ProductController|FaqController|AuthController)" || echo "Some controllers might be missing!"

echo -e "\n${BLUE}📄 Checking view files:${NC}"
echo "Home view:"
ls -la $PROJECT_PATH/resources/views/home.blade.php 2>/dev/null && echo "✅ Found" || echo "❌ Missing"
echo "Products view:"
ls -la $PROJECT_PATH/resources/views/products.blade.php 2>/dev/null && echo "✅ Found" || echo "❌ Missing"
echo "FAQ view:"
ls -la $PROJECT_PATH/resources/views/faq.blade.php 2>/dev/null && echo "✅ Found" || echo "❌ Missing"
echo "Login view:"
ls -la $PROJECT_PATH/resources/views/auth/login.blade.php 2>/dev/null && echo "✅ Found" || echo "❌ Missing"
echo "Register view:"
ls -la $PROJECT_PATH/resources/views/auth/register.blade.php 2>/dev/null && echo "✅ Found" || echo "❌ Missing"

echo -e "\n${BLUE}🗄️  Checking database connection:${NC}"
cd $PROJECT_PATH
php artisan migrate:status | head -n 10

echo -e "\n${BLUE}🔄 Clearing all Laravel caches:${NC}"
cd $PROJECT_PATH
php artisan cache:clear
php artisan config:clear
php artisan view:clear
php artisan route:clear
echo -e "${GREEN}✅ All caches cleared${NC}"

echo -e "\n${BLUE}⚡ Optimizing Laravel for production:${NC}"
cd $PROJECT_PATH
php artisan config:cache
php artisan route:cache
php artisan view:cache
echo -e "${GREEN}✅ Laravel optimized${NC}"

echo -e "\n${BLUE}🌐 Checking Apache configuration:${NC}"
echo "Apache status:"
systemctl status apache2 | head -n 5

echo -e "\nApache virtual host for Laravel:"
cat /etc/apache2/sites-available/laravel.conf 2>/dev/null || echo "❌ Laravel virtual host not found"

echo -e "\nChecking if mod_rewrite is enabled:"
apache2ctl -M | grep rewrite || echo "❌ mod_rewrite not enabled!"

echo -e "\n${BLUE}📊 Checking Laravel logs for errors:${NC}"
cd $PROJECT_PATH
if [ -f "storage/logs/laravel.log" ]; then
    echo "Last 20 lines of Laravel log:"
    tail -n 20 storage/logs/laravel.log
else
    echo "No Laravel log file found"
fi

echo -e "\n${BLUE}🔧 Testing route generation:${NC}"
cd $PROJECT_PATH
echo "Testing route() helper for each page:"
php artisan tinker --execute="echo route('home'); echo PHP_EOL;" 2>/dev/null || echo "❌ Failed to generate home route"
php artisan tinker --execute="echo route('products.index'); echo PHP_EOL;" 2>/dev/null || echo "❌ Failed to generate products route"
php artisan tinker --execute="echo route('faq'); echo PHP_EOL;" 2>/dev/null || echo "❌ Failed to generate faq route"
php artisan tinker --execute="echo route('login'); echo PHP_EOL;" 2>/dev/null || echo "❌ Failed to generate login route"
php artisan tinker --execute="echo route('register'); echo PHP_EOL;" 2>/dev/null || echo "❌ Failed to generate register route"

echo -e "\n${BLUE}📱 Testing direct controller access:${NC}"
cd $PROJECT_PATH
echo "Testing if controllers can be instantiated:"
php -r "
require_once 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';
try {
    new App\Http\Controllers\HomeController();
    echo '✅ HomeController OK' . PHP_EOL;
} catch (Exception \$e) {
    echo '❌ HomeController Error: ' . \$e->getMessage() . PHP_EOL;
}
try {
    new App\Http\Controllers\ProductController();
    echo '✅ ProductController OK' . PHP_EOL;
} catch (Exception \$e) {
    echo '❌ ProductController Error: ' . \$e->getMessage() . PHP_EOL;
}
try {
    new App\Http\Controllers\AuthController();
    echo '✅ AuthController OK' . PHP_EOL;
} catch (Exception \$e) {
    echo '❌ AuthController Error: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n${BLUE}🏠 Testing direct URL access (internal):${NC}"
echo "Testing if URLs respond correctly from server:"
curl -s -o /dev/null -w "Home page: %{http_code}\n" "http://localhost/"
curl -s -o /dev/null -w "Products page: %{http_code}\n" "http://localhost/products" 
curl -s -o /dev/null -w "FAQ page: %{http_code}\n" "http://localhost/faq"
curl -s -o /dev/null -w "Login page: %{http_code}\n" "http://localhost/login"
curl -s -o /dev/null -w "Register page: %{http_code}\n" "http://localhost/register"

echo -e "\n${BLUE}🔍 Environment check:${NC}"
cd $PROJECT_PATH
echo "APP_URL from .env:"
grep "APP_URL" .env || echo "APP_URL not set"
echo "APP_ENV from .env:"
grep "APP_ENV" .env || echo "APP_ENV not set"
echo "APP_DEBUG from .env:"
grep "APP_DEBUG" .env || echo "APP_DEBUG not set"

echo -e "\n${BLUE}🎯 Route comparison - FAQ vs Others:${NC}"
cd $PROJECT_PATH
echo "FAQ route details:"
php artisan route:list | grep faq || echo "FAQ route not found"
echo -e "\nHome route details:"
php artisan route:list | grep -E "GET.*\/\s" || echo "Home route not found"
echo -e "\nProducts route details:"
php artisan route:list | grep products || echo "Products route not found"

echo -e "\n${GREEN}🏁 Debug Analysis Complete!${NC}"
echo "========================================="
echo -e "${YELLOW}📋 Summary of potential issues to check:${NC}"
echo "1. Route caching problems (cleared and rebuilt)"
echo "2. Controller autoloading issues (tested)"
echo "3. Apache mod_rewrite configuration"
echo "4. Virtual host setup"
echo "5. Environment configuration"
echo "6. Direct URL accessibility vs route() helper"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo "1. Check the HTTP status codes above"
echo "2. Verify Apache virtual host serves all routes"
echo "3. Test route() helper output vs direct URL access"
echo "4. Check if the issue is client-side (ERR_CONNECTION_REFUSED) or server-side"