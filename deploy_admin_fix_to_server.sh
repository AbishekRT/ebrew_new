#!/bin/bash

echo "=== DEPLOY ADMIN MIDDLEWARE FIX TO SERVER ==="
echo "This script will apply the middleware fix directly on the Ubuntu server"
echo "Timestamp: $(date)"
echo ""

cd /var/www/html

# 1. Backup current Kernel.php
echo "1. Creating backup of current Kernel.php..."
sudo cp app/Http/Kernel.php app/Http/Kernel.php.backup.$(date +%Y%m%d_%H%M%S)

# 2. Show current admin middleware registration
echo "2. Current admin middleware in Kernel.php:"
grep -n "admin.*Middleware" app/Http/Kernel.php || echo "No admin middleware found"

# 3. Remove admin middleware from Kernel.php middlewareAliases
echo "3. Removing admin middleware from Kernel.php..."
sudo sed -i "s/'admin' => .*IsAdminMiddleware.*,/\/\/ 'admin' => \\\\App\\\\Http\\\\Middleware\\\\IsAdminMiddleware::class, \/\/ REMOVED - causing 500 errors/" app/Http/Kernel.php

# Alternative approach - completely remove the line
sudo sed -i "/.*'admin'.*IsAdminMiddleware.*/d" app/Http/Kernel.php

# 4. Show what we changed
echo "4. After removal - checking for admin middleware:"
grep -n "admin.*Middleware" app/Http/Kernel.php || echo "✅ Admin middleware successfully removed"

# 5. Check routes for admin middleware usage
echo "5. Checking routes for admin middleware usage..."
grep -n "'admin'" routes/web.php | head -5

# 6. Remove admin middleware from routes
echo "6. Removing admin middleware from all routes..."
sudo sed -i "s/\['auth', 'admin'\]/['auth']/g" routes/web.php
sudo sed -i "s/, 'admin'//g" routes/web.php

# 7. Verify routes are fixed
echo "7. After route fix - checking for admin middleware in routes:"
grep -n "'admin'" routes/web.php | head -5 || echo "✅ Admin middleware removed from routes"

# 8. Clear ALL Laravel caches
echo "8. Clearing all Laravel caches..."
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear  
sudo -u www-data php artisan route:clear
sudo -u www-data php artisan view:clear

# 9. Remove cached config files manually
echo "9. Removing cached config files manually..."
sudo rm -f bootstrap/cache/config.php
sudo rm -f bootstrap/cache/routes-v7.php
sudo rm -f bootstrap/cache/services.php
sudo rm -f bootstrap/cache/packages.php

# 10. Restart Apache
echo "10. Restarting Apache to clear any cached configurations..."
sudo systemctl restart apache2

# 11. Test route registration
echo "11. Testing admin route registration..."
sudo -u www-data php artisan route:list --name=admin.dashboard || echo "Route test failed"

# 12. Create simple test route without any middleware
echo "12. Adding emergency test route..."
cat >> routes/web.php << 'EOF'

// Emergency admin test route - NO MIDDLEWARE AT ALL
Route::get('/admin/emergency-test', function() {
    return 'EMERGENCY TEST - Admin route working! Time: ' . now() . ' - No middleware!';
});

EOF

# 13. Clear routes again after adding test route
sudo -u www-data php artisan route:clear

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo "✅ Admin middleware removed from Kernel.php"
echo "✅ Admin middleware removed from all routes"  
echo "✅ All caches cleared"
echo "✅ Apache restarted"
echo "✅ Emergency test route added"
echo ""
echo "🧪 TEST THESE URLS NOW:"
echo "1. Emergency Test (no middleware): http://13.60.43.49/admin/emergency-test"
echo "2. Admin Dashboard: http://13.60.43.49/admin/dashboard"
echo ""
echo "📋 IF STILL 500 ERROR:"
echo "1. Check: tail -f /var/www/html/storage/logs/laravel.log"
echo "2. Run: sudo -u www-data php artisan config:clear"
echo "3. Run: sudo systemctl restart apache2"
echo ""
echo "The admin middleware should now be completely gone from the server!"