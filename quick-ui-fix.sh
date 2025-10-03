#!/bin/bash

# =====================================================================
# QUICK FIX SCRIPT - For Future Reference
# =====================================================================
# Use this script if UI stops working after server/IP changes
# Based on successful fix from October 3, 2025
# =====================================================================

echo "🚀 QUICK UI FIX - Based on Successful Solution"
echo "============================================="

# Check if IP is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <new_ip_address>"
    echo "Example: $0 16.171.119.252"
    exit 1
fi

NEW_IP=$1
echo "Fixing UI for new IP: $NEW_IP"
echo ""

# Step 1: Fix APP_URL in .env
echo "1️⃣ Fixing APP_URL in .env..."
sed -i "s|^APP_URL=.*|APP_URL=http://$NEW_IP|" .env
sed -i "s|^ASSET_URL=.*|ASSET_URL=http://$NEW_IP|" .env
echo "✅ .env updated"

# Step 2: Clear ALL Laravel caches
echo ""
echo "2️⃣ Clearing Laravel caches..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear
rm -f bootstrap/cache/config.php
rm -f bootstrap/cache/routes-*.php
rm -f bootstrap/cache/services.php
echo "✅ Caches cleared"

# Step 3: Test configuration
echo ""
echo "3️⃣ Testing Laravel configuration..."
php -r "
require 'bootstrap/app.php';
echo 'APP_URL: ' . config('app.url') . PHP_EOL;
use Illuminate\\Support\\Facades\\Vite;
try {
    echo 'CSS URL: ' . Vite::asset('resources/css/app.css') . PHP_EOL;
    echo 'Asset resolution: SUCCESS' . PHP_EOL;
} catch (Exception \$e) {
    echo 'Asset resolution: FAILED - ' . \$e->getMessage() . PHP_EOL;
}
"

# Step 4: Set permissions
echo ""
echo "4️⃣ Setting permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
echo "✅ Permissions set"

# Step 5: Restart Apache
echo ""
echo "5️⃣ Restarting Apache..."
systemctl restart apache2
echo "✅ Apache restarted"

# Step 6: Test website
echo ""
echo "6️⃣ Testing website..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$NEW_IP/" || echo "000")
echo "Website status: HTTP $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    echo ""
    echo "🎉 SUCCESS! UI should now be working!"
    echo "Visit: http://$NEW_IP"
else
    echo ""
    echo "⚠️ Still having issues. Check:"
    echo "- Laravel logs: tail -f storage/logs/laravel.log"
    echo "- Debug page: http://$NEW_IP/debug/assets"
fi

echo ""
echo "✅ Quick fix completed!"