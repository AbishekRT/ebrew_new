#!/bin/bash

echo "=== Fix Admin Routing and Dashboard 500 Error ==="
echo "Diagnosing and fixing admin route 500 error..."

# 1. Check Laravel logs for exact error
echo "1. Checking Laravel logs for 500 error..."
echo "=== RECENT LARAVEL LOGS ==="
tail -n 50 /var/www/html/storage/logs/laravel.log

echo ""
echo "=== APACHE ERROR LOGS ==="
tail -n 20 /var/log/apache2/error.log

# 2. Test admin middleware and route directly
echo ""
echo "2. Testing admin route resolution..."
cd /var/www/html

# Check if admin dashboard route exists
php artisan route:list | grep admin.dashboard

echo ""
echo "3. Testing AdminController directly..."
php -r "
require_once 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';
\$kernel = \$app->make(Illuminate\Contracts\Http\Kernel::class);

try {
    // Test if AdminController can be instantiated
    \$controller = new App\Http\Controllers\AdminController();
    echo 'AdminController instantiation: ✅' . PHP_EOL;
    
    // Test database connection
    \$totalProducts = App\Models\Item::count();
    echo 'Database query (Items count): ' . \$totalProducts . ' ✅' . PHP_EOL;
    
    // Test admin view exists
    if (file_exists('resources/views/admin/dashboard.blade.php')) {
        echo 'Admin dashboard view exists: ✅' . PHP_EOL;
    } else {
        echo 'Admin dashboard view missing: ❌' . PHP_EOL;
    }
    
} catch (Exception \$e) {
    echo 'Error: ' . \$e->getMessage() . PHP_EOL;
    echo 'File: ' . \$e->getFile() . ':' . \$e->getLine() . PHP_EOL;
}
"

# 4. Check admin user authentication
echo ""
echo "4. Verifying admin user authentication..."
php -r "
require_once 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';
\$kernel = \$app->make(Illuminate\Contracts\Http\Kernel::class);

\$admin = App\Models\User::where('email', 'prageeshaa@admin.ebrew.com')->first();
if (\$admin) {
    echo 'Admin user found: ' . \$admin->email . PHP_EOL;
    echo 'Role: ' . \$admin->role . PHP_EOL;
    echo 'is_admin field: ' . \$admin->is_admin . PHP_EOL;
    echo 'isAdmin() method: ' . (\$admin->isAdmin() ? 'true' : 'false') . PHP_EOL;
} else {
    echo 'Admin user not found!' . PHP_EOL;
}
"

# 5. Fix potential issues
echo ""
echo "5. Applying fixes for common 500 errors..."

# Clear all caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Ensure proper permissions
sudo chown -R www-data:www-data /var/www/html/storage
sudo chown -R www-data:www-data /var/www/html/bootstrap/cache
sudo chmod -R 775 /var/www/html/storage
sudo chmod -R 775 /var/www/html/bootstrap/cache

# 6. Create debug route for testing
echo ""
echo "6. Creating debug route for admin testing..."
cat > /tmp/debug_admin.php << 'EOF'
<?php
// Add this temporarily to routes/web.php for testing

Route::get('/debug/admin-login-test', function() {
    try {
        // Check authentication
        if (!Auth::check()) {
            return 'Not authenticated';
        }
        
        $user = Auth::user();
        $isAdmin = $user->isAdmin();
        
        if (!$isAdmin) {
            return 'User is not admin: ' . $user->email . ' (Role: ' . $user->role . ', is_admin: ' . $user->is_admin . ')';
        }
        
        // Test AdminController directly
        $controller = new App\Http\Controllers\AdminController();
        
        // Test view compilation
        $totalProducts = App\Models\Item::count();
        $totalOrders = App\Models\Order::count();
        $totalSales = App\Models\Order::sum('SubTotal');
        $topProduct = App\Models\Item::first();
        
        return view('admin.dashboard', compact(
            'totalProducts',
            'totalOrders', 
            'totalSales',
            'topProduct'
        ));
        
    } catch (Exception $e) {
        return 'Error: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine();
    }
});
EOF

echo "Debug route content created. Adding to routes/web.php..."
echo "" >> routes/web.php
cat /tmp/debug_admin.php >> routes/web.php

# 7. Test the admin dashboard components individually
echo ""
echo "7. Testing individual dashboard components..."
php -r "
require_once 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';
\$kernel = \$app->make(Illuminate\Contracts\Http\Kernel::class);

try {
    echo 'Testing Item model: ';
    \$items = App\Models\Item::count();
    echo \$items . ' items found ✅' . PHP_EOL;
    
    echo 'Testing Order model: ';
    \$orders = App\Models\Order::count();  
    echo \$orders . ' orders found ✅' . PHP_EOL;
    
    echo 'Testing Order sum: ';
    \$sales = App\Models\Order::sum('SubTotal');
    echo 'Rs.' . number_format(\$sales, 2) . ' total sales ✅' . PHP_EOL;
    
} catch (Exception \$e) {
    echo 'Database error: ' . \$e->getMessage() . PHP_EOL;
}
"

echo ""
echo "8. Restart Apache to apply all changes..."
sudo systemctl restart apache2

echo ""
echo "=== Fix Complete ==="
echo "✅ Cleared all caches"
echo "✅ Fixed file permissions" 
echo "✅ Added debug route"
echo "✅ Restarted Apache"
echo ""
echo "🧪 TESTING OPTIONS:"
echo "1. Try admin login again: http://13.60.43.49/login"
echo "2. Test debug route: http://13.60.43.49/debug/admin-login-test"
echo "3. Check logs: tail -f /var/www/html/storage/logs/laravel.log"
echo ""
echo "If still getting 500 error, the exact error will be in the logs above."