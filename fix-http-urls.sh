#!/bin/bash

# ===================================================================
# Fix HTTP/HTTPS Issues - Force Laravel to Use HTTP Only
# ===================================================================
# This script ensures all Laravel URLs use HTTP instead of HTTPS
# ===================================================================

set -e

echo "🔧 Fixing HTTP/HTTPS URL Issues for EC2..."
echo "================================================"

cd /var/www/html

echo "📁 Current directory: $(pwd)"
echo "🕐 Time: $(date)"

# ===================================================================
# 1. Update .env File for HTTP
# ===================================================================
echo ""
echo "1️⃣ UPDATING .ENV FILE FOR HTTP"
echo "----------------------------------------"

echo "📝 Current APP_URL setting:"
grep "^APP_URL=" .env || echo "APP_URL not found"

# Update APP_URL to use HTTP with EC2 hostname
echo "🔧 Setting APP_URL to HTTP..."
sudo sed -i 's|^APP_URL=.*|APP_URL=http://ec2-13-60-43-49.eu-north-1.compute.amazonaws.com|' .env

# Also update ASSET_URL if present
if grep -q "^ASSET_URL=" .env; then
    sudo sed -i 's|^ASSET_URL=.*|ASSET_URL=http://ec2-13-60-43-49.eu-north-1.compute.amazonaws.com|' .env
    echo "✅ ASSET_URL updated to HTTP"
fi

# Update SESSION_SECURE_COOKIE to false for HTTP
sudo sed -i 's|^SESSION_SECURE_COOKIE=.*|SESSION_SECURE_COOKIE=false|' .env

# Update SANCTUM_STATEFUL_DOMAINS for HTTP
if grep -q "^SANCTUM_STATEFUL_DOMAINS=" .env; then
    sudo sed -i 's|^SANCTUM_STATEFUL_DOMAINS=.*|SANCTUM_STATEFUL_DOMAINS=ec2-13-60-43-49.eu-north-1.compute.amazonaws.com|' .env
    echo "✅ SANCTUM_STATEFUL_DOMAINS updated"
fi

echo "✅ .env file updated for HTTP"
echo "📝 New APP_URL setting:"
grep "^APP_URL=" .env

# ===================================================================
# 2. Check and Update config/app.php (if needed)
# ===================================================================
echo ""
echo "2️⃣ CHECKING CONFIG/APP.PHP"
echo "----------------------------------------"

echo "📝 Current app.php URL setting:"
grep "'url'" config/app.php | head -1

# The config/app.php should already use env('APP_URL'), so this should be fine
# But let's verify it's not hardcoded
if grep -q "https://" config/app.php; then
    echo "⚠️ Found hardcoded HTTPS URLs in config/app.php"
    # Make a backup
    sudo cp config/app.php config/app.php.backup
    # Replace any hardcoded HTTPS with HTTP
    sudo sed -i 's|https://|http://|g' config/app.php
    echo "✅ Fixed hardcoded HTTPS URLs in config/app.php"
else
    echo "✅ No hardcoded HTTPS URLs found in config/app.php"
fi

# ===================================================================
# 3. Check Common View Files for Hardcoded HTTPS
# ===================================================================
echo ""
echo "3️⃣ CHECKING VIEW FILES FOR HARDCODED HTTPS"
echo "----------------------------------------"

# Check for hardcoded HTTPS URLs in view files
HTTPS_COUNT=$(find resources/views -name "*.blade.php" -exec grep -l "https://" {} \; 2>/dev/null | wc -l)

if [ "$HTTPS_COUNT" -gt 0 ]; then
    echo "⚠️ Found $HTTPS_COUNT view files with hardcoded HTTPS URLs:"
    find resources/views -name "*.blade.php" -exec grep -l "https://" {} \; 2>/dev/null | head -5
    
    echo "🔧 Fixing hardcoded HTTPS in view files..."
    # Fix common patterns
    find resources/views -name "*.blade.php" -exec sudo sed -i 's|https://ec2-|http://ec2-|g' {} \; 2>/dev/null || true
    find resources/views -name "*.blade.php" -exec sudo sed -i 's|https://16\.171\.36\.211|http://16.171.36.211|g' {} \; 2>/dev/null || true
    echo "✅ Fixed hardcoded HTTPS URLs in view files"
else
    echo "✅ No hardcoded HTTPS URLs found in view files"
fi

# ===================================================================
# 4. Check Routes for HTTPS Enforcement
# ===================================================================
echo ""
echo "4️⃣ CHECKING ROUTES FOR HTTPS ENFORCEMENT"
echo "----------------------------------------"

# Check for any HTTPS enforcement in routes
if grep -r "forceHttps\|forceScheme.*https" routes/ 2>/dev/null; then
    echo "⚠️ Found HTTPS enforcement in routes"
    echo "🔧 Consider removing or commenting out HTTPS enforcement"
else
    echo "✅ No HTTPS enforcement found in routes"
fi

# Check web.php for middleware that might force HTTPS
if grep -q "https" routes/web.php 2>/dev/null; then
    echo "⚠️ Found HTTPS references in routes/web.php"
    grep -n "https" routes/web.php 2>/dev/null | head -3
else
    echo "✅ No HTTPS references in routes/web.php"
fi

# ===================================================================
# 5. Check for AppServiceProvider URL Forcing
# ===================================================================
echo ""
echo "5️⃣ CHECKING APP SERVICE PROVIDER"
echo "----------------------------------------"

if [ -f "app/Providers/AppServiceProvider.php" ]; then
    echo "📝 Checking AppServiceProvider for URL forcing..."
    
    if grep -q "forceHttps\|forceScheme" app/Providers/AppServiceProvider.php; then
        echo "⚠️ Found URL forcing in AppServiceProvider"
        grep -n "forceHttps\|forceScheme" app/Providers/AppServiceProvider.php
        
        echo "🔧 Commenting out HTTPS forcing..."
        sudo sed -i 's|URL::forceHttps();|// URL::forceHttps(); // Commented for HTTP-only EC2|' app/Providers/AppServiceProvider.php
        sudo sed -i 's|URL::forceScheme.*https.*;|// URL::forceScheme("https"); // Commented for HTTP-only EC2|' app/Providers/AppServiceProvider.php
        echo "✅ HTTPS forcing commented out"
    else
        echo "✅ No URL forcing found in AppServiceProvider"
    fi
else
    echo "⚠️ AppServiceProvider not found"
fi

# ===================================================================
# 6. Clear All Laravel Caches
# ===================================================================
echo ""
echo "6️⃣ CLEARING ALL LARAVEL CACHES"
echo "----------------------------------------"

echo "🧹 Clearing Laravel caches..."

# Clear all caches
sudo -u www-data php artisan config:clear
echo "✅ Config cache cleared"

sudo -u www-data php artisan cache:clear
echo "✅ Application cache cleared"

sudo -u www-data php artisan route:clear
echo "✅ Route cache cleared"

sudo -u www-data php artisan view:clear
echo "✅ View cache cleared"

# Clear any cached URLs
sudo -u www-data php artisan optimize:clear 2>/dev/null || echo "Optimize clear not available"

# ===================================================================
# 7. Cache New Configuration
# ===================================================================
echo ""
echo "7️⃣ CACHING NEW CONFIGURATION"
echo "----------------------------------------"

echo "⚡ Caching new HTTP configuration..."

sudo -u www-data php artisan config:cache
echo "✅ Config cached with new HTTP settings"

sudo -u www-data php artisan route:cache
echo "✅ Routes cached"

sudo -u www-data php artisan view:cache
echo "✅ Views cached"

# ===================================================================
# 8. Restart Apache
# ===================================================================
echo ""
echo "8️⃣ RESTARTING APACHE"
echo "----------------------------------------"

echo "🔄 Restarting Apache..."
sudo systemctl restart apache2

if systemctl is-active --quiet apache2; then
    echo "✅ Apache restarted successfully"
else
    echo "❌ Apache restart failed"
    sudo systemctl status apache2
fi

# ===================================================================
# 9. Test HTTP URLs
# ===================================================================
echo ""
echo "9️⃣ TESTING HTTP URLS"
echo "----------------------------------------"

echo "🌐 Testing HTTP URLs..."

# Test homepage with HTTP
HTTP_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null)
echo "Homepage HTTP test: $HTTP_TEST"

# Test if Laravel is generating correct URLs
echo "🔍 Testing Laravel URL generation..."
URL_TEST=$(sudo -u www-data php artisan tinker --execute="echo url('/');" 2>/dev/null)
echo "Laravel generates URL: $URL_TEST"

if [[ "$URL_TEST" == *"http://"* ]] && [[ "$URL_TEST" != *"https://"* ]]; then
    echo "✅ Laravel is generating HTTP URLs correctly"
else
    echo "⚠️ Laravel might still be generating HTTPS URLs: $URL_TEST"
fi

# Test a few common routes
echo ""
echo "🔍 Testing common routes with HTTP..."

# Test products route if it exists
PRODUCTS_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/products 2>/dev/null)
echo "Products page: HTTP $PRODUCTS_TEST"

# Test about route if it exists
ABOUT_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/about 2>/dev/null)
echo "About page: HTTP $ABOUT_TEST"

# ===================================================================
# 10. Check for Redirect Loops
# ===================================================================
echo ""
echo "🔟 CHECKING FOR REDIRECT LOOPS"
echo "----------------------------------------"

echo "🔍 Checking for redirect behavior..."
REDIRECT_CHECK=$(curl -s -I http://localhost/ | grep -i location | head -1)

if [ -n "$REDIRECT_CHECK" ]; then
    echo "⚠️ Found redirect: $REDIRECT_CHECK"
    if [[ "$REDIRECT_CHECK" == *"https://"* ]]; then
        echo "❌ Still redirecting to HTTPS - need to fix redirect source"
    else
        echo "✅ Redirect is using HTTP"
    fi
else
    echo "✅ No redirects detected"
fi

# ===================================================================
# 11. Final Summary
# ===================================================================
echo ""
echo "1️⃣1️⃣ SUMMARY"
echo "========================================="

echo ""
echo "🎯 HTTP CONFIGURATION STATUS:"
echo "- APP_URL: $(grep '^APP_URL=' .env | cut -d= -f2)"
echo "- Laravel URL generation: $URL_TEST"
echo "- Homepage: HTTP $HTTP_TEST"
echo "- Products page: HTTP $PRODUCTS_TEST"
echo "- Apache status: $(systemctl is-active apache2)"

echo ""
echo "🔍 TEST YOUR APPLICATION:"
echo "✅ HTTP URL: http://ec2-13-60-43-49.eu-north-1.compute.amazonaws.com/"
echo "✅ Products: http://ec2-13-60-43-49.eu-north-1.compute.amazonaws.com/products"
echo "✅ IP Address: http://16.171.36.211/"

echo ""
echo "🚨 TROUBLESHOOTING:"
if [ "$HTTP_TEST" = "200" ]; then
    echo "✅ Application is working with HTTP!"
    echo "   All links should now use HTTP instead of HTTPS"
else
    echo "⚠️ Still having issues (HTTP $HTTP_TEST)"
    echo "   1. Check Laravel logs: tail -f storage/logs/laravel.log"
    echo "   2. Check Apache logs: sudo tail -f /var/log/apache2/error.log"
    echo "   3. Test manually: curl -I http://localhost/"
fi

echo ""
echo "✅ HTTP/HTTPS fix script completed!"
echo "🌐 Your application should now work with HTTP URLs only"