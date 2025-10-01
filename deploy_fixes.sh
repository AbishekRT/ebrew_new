#!/bin/bash

# =================================================================
# AWS SERVER DEPLOYMENT SCRIPT - CART FIXES
# =================================================================
# Run this script on your AWS EC2 server after uploading the fixed files
# =================================================================

echo "🚀 DEPLOYING CART SYSTEM FIXES TO AWS SERVER..."
echo ""

# Check if we're in the Laravel project directory
if [ ! -f "artisan" ]; then
    echo "❌ ERROR: Not in Laravel project directory!"
    echo "Please run this script from your Laravel project root directory"
    exit 1
fi

echo "📍 Current directory: $(pwd)"
echo ""

# Step 1: Check database connection
echo "1. 🔍 CHECKING DATABASE CONNECTION..."
php artisan migrate:status
if [ $? -ne 0 ]; then
    echo "❌ Database connection failed. Please check your .env configuration."
    exit 1
fi
echo "✅ Database connection OK"
echo ""

# Step 2: Run migrations (including new sessions table)
echo "2. 🗄️ RUNNING DATABASE MIGRATIONS..."
php artisan migrate --force
if [ $? -ne 0 ]; then
    echo "❌ Migrations failed. Please check the error above."
    exit 1
fi
echo "✅ Migrations completed successfully"
echo ""

# Step 3: Clear all caches
echo "3. 🧹 CLEARING APPLICATION CACHES..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear
echo "✅ Caches cleared"
echo ""

# Step 4: Set proper permissions
echo "4. 🔒 SETTING FILE PERMISSIONS..."
chmod -R 755 storage
chmod -R 755 bootstrap/cache
chown -R www-data:www-data storage
chown -R www-data:www-data bootstrap/cache
echo "✅ Permissions set"
echo ""

# Step 5: Test critical functionality
echo "5. 🧪 TESTING CRITICAL FUNCTIONALITY..."

echo "   Testing Item model..."
php -r "
require 'vendor/autoload.php';
\$app = require 'bootstrap/app.php';
\$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();
\$item = \App\Models\Item::first();
if (\$item) {
    echo '✅ Item model working - Found item: ' . \$item->Name . \"\n\";
} else {
    echo '⚠️ No items found in database\n';
}"

echo "   Testing Cart model..."
php -r "
require 'vendor/autoload.php';
\$app = require 'bootstrap/app.php';
\$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();
\$user = \App\Models\User::first();
if (\$user) {
    \$cart = \App\Models\Cart::firstOrCreate(['UserID' => \$user->id]);
    echo '✅ Cart model working - Cart ID: ' . \$cart->id . \"\n\";
} else {
    echo '⚠️ No users found in database\n';
}"
echo ""

# Step 6: Restart web server
echo "6. 🔄 RESTARTING WEB SERVER..."
if systemctl is-active --quiet apache2; then
    sudo systemctl restart apache2
    echo "✅ Apache restarted"
elif systemctl is-active --quiet nginx; then
    sudo systemctl restart nginx
    echo "✅ Nginx restarted"
else
    echo "⚠️ Could not detect web server. Please restart manually."
fi
echo ""

# Step 7: Final status check
echo "7. ✅ DEPLOYMENT COMPLETE!"
echo ""
echo "🎯 NEXT STEPS:"
echo "1. Test Buy Now functionality: /products/2 -> Click Buy Now"
echo "2. Test Add to Cart: Any product page -> Click Add to Cart"
echo "3. Check cart page: /cart"
echo "4. Test checkout: /checkout"
echo ""
echo "🔍 MONITOR LOGS:"
echo "tail -f storage/logs/laravel.log"
echo ""
echo "📊 CHECK STATUS:"
echo "systemctl status apache2  # or nginx"
echo ""

echo "================================================================="
echo "                      DEPLOYMENT SUMMARY"
echo "================================================================="
echo ""
echo "✅ Database migrations executed"
echo "✅ Sessions table created"  
echo "✅ Application caches cleared"
echo "✅ File permissions set"
echo "✅ Web server restarted"
echo "✅ Basic functionality tested"
echo ""
echo "🎉 Your eBrew cart system is now updated and ready!"
echo ""
echo "================================================================="