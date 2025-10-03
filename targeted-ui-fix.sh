#!/bin/bash

# =====================================================================
# TARGETED UI FIX - Based on Previous Successful Solutions
# =====================================================================
# This script addresses the actual root cause based on debugging info
# =====================================================================

echo "🎯 TARGETED UI FIX - Laravel Vite Asset Resolution"
echo "================================================="
echo "Time: $(date)"
echo ""

cd /var/www/html

# =====================================================================
# PHASE 1: DEBUG CURRENT STATE
# =====================================================================
echo "🔍 PHASE 1: DEBUGGING CURRENT ASSET RESOLUTION"
echo "=============================================="

echo "📋 Testing Vite asset URL generation..."

# Test what URLs Laravel's Vite helper is actually generating
php artisan tinker --execute="
echo '=== VITE DEBUG INFORMATION ===' . PHP_EOL;
echo 'APP_URL: ' . config('app.url') . PHP_EOL;
echo 'APP_ENV: ' . config('app.env') . PHP_EOL;

use Illuminate\\Support\\Facades\\Vite;

try {
    echo 'CSS Asset URL: ' . Vite::asset('resources/css/app.css') . PHP_EOL;
    echo 'JS Asset URL: ' . Vite::asset('resources/js/app.js') . PHP_EOL;
} catch (Exception \$e) {
    echo 'Vite Error: ' . \$e->getMessage() . PHP_EOL;
    echo 'This means Laravel cannot resolve asset URLs!' . PHP_EOL;
}

echo 'Manifest Path: ' . public_path('build/manifest.json') . PHP_EOL;
echo 'Manifest Exists: ' . (file_exists(public_path('build/manifest.json')) ? 'YES' : 'NO') . PHP_EOL;

if (file_exists(public_path('build/manifest.json'))) {
    echo 'Manifest Content: ' . file_get_contents(public_path('build/manifest.json')) . PHP_EOL;
}
"

echo ""
echo "🌐 Testing actual HTTP access to assets..."

# Test if manifest is accessible via HTTP
MANIFEST_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/build/manifest.json || echo "000")
echo "Manifest HTTP access: $MANIFEST_HTTP"

# Test if CSS file is accessible
if [ -f "public/build/assets/app-"*.css ]; then
    CSS_FILE=$(ls public/build/assets/app-*.css | head -1 | sed 's|public/||')
    CSS_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/$CSS_FILE" || echo "000")
    echo "CSS HTTP access: $CSS_HTTP ($CSS_FILE)"
    
    # Test actual content
    if [ "$CSS_HTTP" = "200" ]; then
        CSS_SIZE=$(curl -s "http://localhost/$CSS_FILE" | wc -c)
        echo "CSS file size: $CSS_SIZE bytes"
        if [ "$CSS_SIZE" -lt "1000" ]; then
            echo "⚠️  CSS file is suspiciously small"
        fi
    fi
else
    echo "❌ No CSS files found in public/build/assets/"
fi

# =====================================================================
# PHASE 2: CHECK IF ISSUE IS .HTACCESS or APACHE CONFIG
# =====================================================================
echo ""
echo "🔍 PHASE 2: CHECK APACHE CONFIGURATION"
echo "=============================================="

echo "📋 Checking .htaccess in public directory..."
if [ -f "public/.htaccess" ]; then
    echo "✅ .htaccess exists"
    echo "Content preview:"
    head -10 public/.htaccess
else
    echo "❌ .htaccess missing! Creating Laravel default..."
    cat > public/.htaccess << 'EOF'
<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>

    RewriteEngine On

    # Handle Authorization Header
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    # Redirect Trailing Slashes If Not A Folder...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} (.+)/$
    RewriteRule ^ %1 [L,R=301]

    # Send Requests To Front Controller...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
EOF
    echo "✅ .htaccess created"
fi

# =====================================================================
# PHASE 3: FIX POTENTIAL BOOTSTRAP.JS ISSUE
# =====================================================================
echo ""
echo "🔍 PHASE 3: CHECK BOOTSTRAP.JS DEPENDENCY"
echo "=============================================="

echo "📋 Checking resources/js/bootstrap.js..."
if [ ! -f "resources/js/bootstrap.js" ]; then
    echo "❌ bootstrap.js missing! This breaks app.js import"
    echo "Creating resources/js/bootstrap.js..."
    mkdir -p resources/js
    cat > resources/js/bootstrap.js << 'EOF'
import axios from 'axios';
window.axios = axios;

window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';

// Add CSRF token to all requests
let token = document.head.querySelector('meta[name="csrf-token"]');

if (token) {
    window.axios.defaults.headers.common['X-CSRF-TOKEN'] = token.content;
} else {
    console.error('CSRF token not found: https://laravel.com/docs/csrf#csrf-x-csrf-token');
}
EOF
    echo "✅ bootstrap.js created"
else
    echo "✅ bootstrap.js exists"
fi

# =====================================================================
# PHASE 4: REBUILD ASSETS WITH CORRECT DEPENDENCIES
# =====================================================================
echo ""
echo "🔨 PHASE 4: REBUILD WITH DEPENDENCY FIX"
echo "=============================================="

echo "🧹 Clearing build cache..."
rm -rf public/build/*
rm -rf node_modules/.vite*

echo "🔨 Rebuilding assets..."
export NODE_ENV=production
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Build completed successfully"
    
    # Show build results
    if [ -f "public/build/manifest.json" ]; then
        echo "📋 New manifest content:"
        cat public/build/manifest.json
    fi
    
    if [ -d "public/build/assets" ]; then
        echo "📋 New asset files:"
        ls -la public/build/assets/
    fi
else
    echo "❌ Build failed again"
fi

# =====================================================================
# PHASE 5: TEST ASSET RESOLUTION AGAIN
# =====================================================================
echo ""
echo "🔍 PHASE 5: RETEST ASSET RESOLUTION"
echo "=============================================="

echo "🌐 Testing Laravel Vite asset resolution after rebuild..."
php artisan tinker --execute="
use Illuminate\\Support\\Facades\\Vite;
try {
    echo 'NEW CSS URL: ' . Vite::asset('resources/css/app.css') . PHP_EOL;
    echo 'NEW JS URL: ' . Vite::asset('resources/js/app.js') . PHP_EOL;
    echo 'Asset resolution: SUCCESS' . PHP_EOL;
} catch (Exception \$e) {
    echo 'Asset resolution: FAILED - ' . \$e->getMessage() . PHP_EOL;
}
"

# =====================================================================
# PHASE 6: CLEAR LARAVEL CACHES (CRITICAL!)
# =====================================================================
echo ""
echo "🧹 PHASE 6: CLEAR LARAVEL CACHES"
echo "=============================================="

echo "🧹 Clearing ALL Laravel caches..."
php artisan config:clear
php artisan route:clear  
php artisan view:clear
php artisan cache:clear

# Clear compiled files
rm -rf bootstrap/cache/config.php
rm -rf bootstrap/cache/routes-*.php
rm -rf bootstrap/cache/services.php

echo "✅ All caches cleared"

# =====================================================================
# PHASE 7: SET CORRECT PERMISSIONS
# =====================================================================
echo ""
echo "🔒 PHASE 7: FIX PERMISSIONS"
echo "=============================================="

echo "🔒 Setting ownership and permissions..."
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Special permissions
chmod -R 775 /var/www/html/storage
chmod -R 775 /var/www/html/bootstrap/cache

echo "✅ Permissions set correctly"

# =====================================================================
# PHASE 8: RESTART APACHE
# =====================================================================
echo ""
echo "🔄 PHASE 8: RESTART APACHE"  
echo "=============================================="

systemctl restart apache2
sleep 2

if systemctl is-active --quiet apache2; then
    echo "✅ Apache restarted successfully"
else
    echo "❌ Apache restart failed"
    systemctl status apache2
fi

# =====================================================================
# PHASE 9: FINAL VERIFICATION
# =====================================================================
echo ""
echo "🔍 PHASE 9: FINAL VERIFICATION"
echo "=============================================="

echo "🌐 Testing website..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "000")
echo "Main page: HTTP $HTTP_CODE"

echo ""
echo "🌐 Testing debug assets page..."
DEBUG_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/debug/assets || echo "000")
echo "Debug page: HTTP $DEBUG_CODE"

if [ "$DEBUG_CODE" = "200" ]; then
    echo ""
    echo "✅ SUCCESS! Debug page accessible"
    echo "🔍 Visit: http://16.171.119.252/debug/assets"
    echo "This page will show you exactly what URLs Laravel is generating"
else
    echo "❌ Debug page not accessible"
fi

# =====================================================================
# PHASE 10: SUMMARY AND NEXT STEPS
# =====================================================================
echo ""
echo "📋 PHASE 10: SUMMARY"
echo "=============================================="

echo ""
echo "🎯 TARGETED FIX COMPLETED"
echo "========================="

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Website: Accessible (HTTP $HTTP_CODE)"
else
    echo "❌ Website: Issue (HTTP $HTTP_CODE)"
fi

if [ "$DEBUG_CODE" = "200" ]; then
    echo "✅ Debug page: Accessible - use this to diagnose asset URLs"
else
    echo "❌ Debug page: Not accessible"
fi

echo ""
echo "🔍 IMMEDIATE NEXT STEPS:"
echo "1. Visit: http://16.171.119.252/debug/assets"
echo "2. Check what URLs Laravel is generating for CSS/JS"
echo "3. Test those URLs directly in browser"
echo "4. Check browser console (F12) for any 404 errors"

echo ""
echo "🎯 IF STILL NO UI:"
echo "The issue is likely one of these:"
echo "• Laravel generating wrong asset URLs (check debug page)"  
echo "• Apache not serving static files from /build/ directory"
echo "• .htaccess blocking asset requests"
echo "• Missing CSRF token or other JS errors"

echo ""
echo "✅ TARGETED FIX COMPLETED!"
echo "Time: $(date)"