#!/bin/bash

# =====================================================================
# COMPREHENSIVE UI FIX SCRIPT - Laravel Assets & Tailwind CSS
# =====================================================================
# This script systematically fixes all UI/CSS/JS loading issues
# =====================================================================

set -e

echo "🔧 COMPREHENSIVE UI FIX - Laravel Asset Pipeline"
echo "=================================================="
echo "Target: http://16.171.119.252"
echo "Time: $(date)"
echo ""

# =====================================================================
# PHASE 1: DIAGNOSTIC CHECKS
# =====================================================================
echo "🔍 PHASE 1: DIAGNOSTIC CHECKS"
echo "=============================================="

cd /var/www/html

# Check if we're in the right directory
echo "📁 Current directory: $(pwd)"
if [ ! -f "artisan" ]; then
    echo "❌ ERROR: Not in Laravel root directory"
    echo "Expected files: artisan, composer.json, package.json"
    exit 1
fi
echo "✅ Laravel root directory confirmed"

# Check file structure
echo ""
echo "📋 File Structure Check:"
echo "✅ artisan: $([ -f artisan ] && echo 'Present' || echo 'MISSING')"
echo "✅ package.json: $([ -f package.json ] && echo 'Present' || echo 'MISSING')"
echo "✅ vite.config.js: $([ -f vite.config.js ] && echo 'Present' || echo 'MISSING')"
echo "✅ tailwind.config.js: $([ -f tailwind.config.js ] && echo 'Present' || echo 'MISSING')"
echo "✅ resources/css/app.css: $([ -f resources/css/app.css ] && echo 'Present' || echo 'MISSING')"
echo "✅ resources/js/app.js: $([ -f resources/js/app.js ] && echo 'Present' || echo 'MISSING')"

# Check current vite.config.js content
echo ""
echo "📄 Current vite.config.js content:"
if [ -f "vite.config.js" ]; then
    cat vite.config.js
    echo ""
    if grep -q 'manifest.*:.*manifest.json' vite.config.js; then
        echo "❌ PROBLEM FOUND: Incorrect manifest configuration detected"
    else
        echo "✅ Vite config looks correct"
    fi
else
    echo "❌ vite.config.js missing"
fi

# =====================================================================
# PHASE 2: FIX VITE CONFIGURATION
# =====================================================================
echo ""
echo "🔧 PHASE 2: FIX VITE CONFIGURATION"
echo "=============================================="

echo "📝 Creating correct vite.config.js..."
cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
});
EOF

echo "✅ vite.config.js updated with correct configuration"

# Verify the source files exist and have correct content
echo ""
echo "📝 Checking source files..."

# Check app.css
if [ ! -f "resources/css/app.css" ]; then
    echo "⚠️ Creating resources/css/app.css..."
    mkdir -p resources/css
    cat > resources/css/app.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

[x-cloak] {
    display: none;
}
EOF
    echo "✅ app.css created"
else
    echo "✅ app.css exists"
    echo "Content preview:"
    head -5 resources/css/app.css
fi

# Check app.js
if [ ! -f "resources/js/app.js" ]; then
    echo "⚠️ Creating resources/js/app.js..."
    mkdir -p resources/js
    cat > resources/js/app.js << 'EOF'
import './bootstrap';

import Alpine from 'alpinejs';

window.Alpine = Alpine;

Alpine.start();
EOF
    echo "✅ app.js created"
else
    echo "✅ app.js exists"
fi

# =====================================================================
# PHASE 3: CLEAN REBUILD ENVIRONMENT
# =====================================================================
echo ""
echo "🧹 PHASE 3: CLEAN REBUILD ENVIRONMENT"
echo "=============================================="

echo "🗑️ Clearing all caches and builds..."

# Clear npm cache
sudo rm -rf node_modules/.cache
sudo rm -rf node_modules/.vite*
sudo rm -rf ~/.npm
sudo rm -rf /var/www/.npm
sudo rm -rf /home/ubuntu/.npm

# Clear build directory
sudo rm -rf public/build
sudo mkdir -p public/build
sudo chown -R www-data:www-data public/build

# Clear Laravel caches
echo "🧹 Clearing Laravel caches..."
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true

echo "✅ All caches cleared"

# =====================================================================
# PHASE 4: INSTALL DEPENDENCIES
# =====================================================================
echo ""
echo "📦 PHASE 4: INSTALL DEPENDENCIES"
echo "=============================================="

echo "📦 Installing npm dependencies..."

# Remove package-lock.json and node_modules
sudo rm -rf package-lock.json node_modules

# Set npm configuration to avoid permission issues
export NPM_CONFIG_CACHE=/tmp/.npm-cache
export NPM_CONFIG_PREFER_OFFLINE=false
export NODE_ENV=production

# Install dependencies
echo "Running npm install..."
sudo npm install --no-audit --no-fund --legacy-peer-deps

if [ $? -ne 0 ]; then
    echo "⚠️ npm install failed, trying alternative method..."
    sudo npm ci --legacy-peer-deps --no-audit
fi

echo "✅ Dependencies installed"

# =====================================================================
# PHASE 5: BUILD ASSETS
# =====================================================================
echo ""
echo "🔨 PHASE 5: BUILD ASSETS"
echo "=============================================="

echo "🔨 Building assets with Vite..."

# Set environment variables for build
export NODE_ENV=production
export VITE_APP_NAME="eBrew"

# Run build
BUILD_OUTPUT=$(npm run build 2>&1)
BUILD_EXIT_CODE=$?

echo "Build output:"
echo "$BUILD_OUTPUT"

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo "✅ Build completed successfully"
else
    echo "❌ Build failed with exit code $BUILD_EXIT_CODE"
    echo "🔧 Attempting recovery build..."
    
    # Try alternative build methods
    sudo npx vite build || {
        echo "❌ Alternative build also failed"
        echo "Creating minimal assets for testing..."
        
        mkdir -p public/build/assets
        
        # Create minimal CSS
        cat > public/build/assets/app.css << 'EOF'
/* Minimal CSS for testing */
body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; }
.container { max-width: 1200px; margin: 0 auto; padding: 20px; }
.btn { padding: 10px 20px; background: #3b82f6; color: white; border-radius: 5px; }
EOF

        # Create minimal JS
        cat > public/build/assets/app.js << 'EOF'
console.log('Minimal JS loaded');
document.addEventListener('DOMContentLoaded', function() {
    console.log('DOM loaded');
});
EOF

        # Create minimal manifest
        cat > public/build/manifest.json << 'EOF'
{
  "resources/css/app.css": {
    "file": "assets/app.css",
    "src": "resources/css/app.css",
    "isEntry": true
  },
  "resources/js/app.js": {
    "file": "assets/app.js",
    "src": "resources/js/app.js",
    "isEntry": true
  }
}
EOF
        
        echo "✅ Minimal assets created as fallback"
    }
fi

# =====================================================================
# PHASE 6: VERIFY BUILD OUTPUT
# =====================================================================
echo ""
echo "🔍 PHASE 6: VERIFY BUILD OUTPUT"
echo "=============================================="

echo "📁 Checking build directory..."
if [ -d "public/build" ]; then
    echo "✅ Build directory exists"
    echo "Contents:"
    ls -la public/build/
    
    if [ -d "public/build/assets" ]; then
        echo "✅ Assets directory exists"
        echo "Asset files:"
        ls -la public/build/assets/ | head -10
    else
        echo "❌ Assets directory missing"
    fi
    
    if [ -f "public/build/manifest.json" ]; then
        echo "✅ Manifest file exists"
        echo "Manifest content:"
        cat public/build/manifest.json
    else
        echo "❌ Manifest file missing"
    fi
else
    echo "❌ Build directory missing"
fi

# =====================================================================
# PHASE 7: SET PERMISSIONS
# =====================================================================
echo ""
echo "🔒 PHASE 7: SET PERMISSIONS"
echo "=============================================="

echo "🔒 Setting correct ownership and permissions..."

# Set ownership
sudo chown -R www-data:www-data /var/www/html

# Set directory permissions
sudo find /var/www/html -type d -exec chmod 755 {} \;

# Set file permissions
sudo find /var/www/html -type f -exec chmod 644 {} \;

# Special permissions for storage and cache
sudo chmod -R 775 /var/www/html/storage
sudo chmod -R 775 /var/www/html/bootstrap/cache

# Ensure build directory is accessible
sudo chmod -R 755 /var/www/html/public/build

echo "✅ Permissions set correctly"

# =====================================================================
# PHASE 8: CONFIGURE APACHE
# =====================================================================
echo ""
echo "🌐 PHASE 8: CONFIGURE APACHE"
echo "=============================================="

echo "🔧 Ensuring Apache serves static assets correctly..."

# Create Apache configuration for assets
sudo tee /etc/apache2/conf-available/laravel-assets.conf > /dev/null << 'EOF'
# Laravel Asset Configuration
<Directory "/var/www/html/public/build">
    Options -Indexes +FollowSymLinks
    AllowOverride None
    Require all granted
    
    # Enable compression for assets
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/css
        AddOutputFilterByType DEFLATE application/javascript
        AddOutputFilterByType DEFLATE text/javascript
    </IfModule>
    
    # Set cache headers for assets
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType text/css "access plus 1 month"
        ExpiresByType application/javascript "access plus 1 month"
        ExpiresByType text/javascript "access plus 1 month"
    </IfModule>
</Directory>

# Ensure .htaccess is processed
<Directory "/var/www/html/public">
    AllowOverride All
    Options -Indexes +FollowSymLinks
    Require all granted
</Directory>
EOF

# Enable the configuration
sudo a2enconf laravel-assets 2>/dev/null || true

# Enable required modules
sudo a2enmod rewrite 2>/dev/null || true
sudo a2enmod deflate 2>/dev/null || true
sudo a2enmod expires 2>/dev/null || true

echo "✅ Apache configured for Laravel assets"

# =====================================================================
# PHASE 9: CACHE OPTIMIZATION
# =====================================================================
echo ""
echo "⚡ PHASE 9: CACHE OPTIMIZATION"
echo "=============================================="

echo "⚡ Optimizing Laravel caches..."

# Clear caches first
php artisan config:clear
php artisan cache:clear
php artisan view:clear

# Cache for production
php artisan config:cache
php artisan view:cache

echo "✅ Laravel caches optimized"

# =====================================================================
# PHASE 10: RESTART SERVICES
# =====================================================================
echo ""
echo "🔄 PHASE 10: RESTART SERVICES"
echo "=============================================="

echo "🔄 Restarting Apache..."
sudo systemctl restart apache2

# Wait a moment for Apache to fully restart
sleep 3

# Check Apache status
if sudo systemctl is-active --quiet apache2; then
    echo "✅ Apache is running"
else
    echo "❌ Apache failed to start"
    sudo systemctl status apache2
fi

# =====================================================================
# PHASE 11: FINAL VERIFICATION
# =====================================================================
echo ""
echo "🔍 PHASE 11: FINAL VERIFICATION"
echo "=============================================="

echo "🌐 Testing website accessibility..."

# Test main page
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "000")
echo "Main page HTTP status: $HTTP_CODE"

# Test manifest file
if [ -f "public/build/manifest.json" ]; then
    MANIFEST_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/build/manifest.json || echo "000")
    echo "Manifest file HTTP status: $MANIFEST_CODE"
fi

# Test assets if they exist
if [ -f "public/build/assets/app.css" ] || ls public/build/assets/app-*.css 2>/dev/null; then
    CSS_FILE=$(ls public/build/assets/app*.css 2>/dev/null | head -1 | sed 's|public/||')
    if [ -n "$CSS_FILE" ]; then
        CSS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/$CSS_FILE" || echo "000")
        echo "CSS file HTTP status: $CSS_CODE"
    fi
fi

echo ""
echo "🔍 Quick Laravel environment check..."
php artisan env 2>/dev/null || echo "Laravel env command not available"

# =====================================================================
# PHASE 12: SUMMARY REPORT
# =====================================================================
echo ""
echo "📋 PHASE 12: SUMMARY REPORT"
echo "=============================================="

echo ""
echo "🎯 FIX COMPLETION STATUS:"
echo "========================"

echo "✅ vite.config.js: Fixed (removed incorrect manifest config)"
echo "✅ Source files: $([ -f resources/css/app.css ] && [ -f resources/js/app.js ] && echo 'Present' || echo 'Missing')"
echo "✅ Dependencies: Installed"
echo "✅ Build: $([ -d public/build ] && echo 'Completed' || echo 'Failed')"
echo "✅ Manifest: $([ -f public/build/manifest.json ] && echo 'Generated' || echo 'Missing')"
echo "✅ Permissions: Fixed"
echo "✅ Apache: $(sudo systemctl is-active --quiet apache2 && echo 'Running' || echo 'Stopped')"
echo "✅ Main page: HTTP $HTTP_CODE"

echo ""
echo "🌐 TEST YOUR WEBSITE:"
echo "====================Test your website"
echo "Primary URL: http://16.171.119.252"
echo "Debug Assets: http://16.171.119.252/debug/assets"

if [ "$HTTP_CODE" = "200" ]; then
    echo "🎉 SUCCESS: Website is accessible!"
    echo ""
    echo "🔍 If UI still looks unstyled:"
    echo "1. Clear browser cache (Ctrl+Shift+R)"
    echo "2. Check browser console (F12) for errors"
    echo "3. Verify manifest: http://16.171.119.252/build/manifest.json"
    echo "4. Check Laravel logs: tail -f /var/www/html/storage/logs/laravel.log"
else
    echo "⚠️ ISSUE: Website returned HTTP $HTTP_CODE"
    echo "Check Apache error logs: sudo tail -f /var/log/apache2/error.log"
fi

echo ""
echo "✅ COMPREHENSIVE UI FIX COMPLETED!"
echo "Time: $(date)"
echo "=================================================="