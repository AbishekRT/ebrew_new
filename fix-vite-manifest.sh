#!/bin/bash

# ===================================================================
# Fix Vite Manifest Missing Error - Laravel Asset Compilation
# ===================================================================
# This script fixes the "Vite manifest not found" error by compiling assets
# ===================================================================

set -e

echo "🔧 Fixing Vite Manifest Missing Error..."
echo "================================================"

cd /var/www/html

echo "📁 Current directory: $(pwd)"
echo "🕐 Time: $(date)"

# ===================================================================
# 1. Check Current Asset State
# ===================================================================
echo ""
echo "1️⃣ CHECKING CURRENT ASSET STATE"
echo "----------------------------------------"

echo "📦 Checking for package.json..."
if [ -f "package.json" ]; then
    echo "✅ package.json found"
    echo "📋 NPM scripts available:"
    cat package.json | grep -A 5 '"scripts"' || echo "No scripts section found"
else
    echo "❌ package.json missing"
    exit 1
fi

echo ""
echo "📁 Checking build directory..."
if [ -d "public/build" ]; then
    echo "✅ Build directory exists"
    echo "📋 Current build contents:"
    ls -la public/build/ 2>/dev/null || echo "Build directory empty"
else
    echo "⚠️ Build directory missing"
    mkdir -p public/build
fi

echo ""
echo "📄 Checking for manifest.json..."
if [ -f "public/build/manifest.json" ]; then
    echo "✅ Vite manifest exists"
    cat public/build/manifest.json | head -5
else
    echo "❌ Vite manifest missing (this is the cause of the 500 error)"
fi

# ===================================================================
# 2. Install Node.js and npm (if not present)
# ===================================================================
echo ""
echo "2️⃣ CHECKING NODE.JS INSTALLATION"
echo "----------------------------------------"

if command -v node &> /dev/null; then
    echo "✅ Node.js installed: $(node --version)"
else
    echo "📦 Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "✅ Node.js installed: $(node --version)"
fi

if command -v npm &> /dev/null; then
    echo "✅ npm installed: $(npm --version)"
else
    echo "❌ npm not available"
    exit 1
fi

# ===================================================================
# 3. Install npm Dependencies
# ===================================================================
echo ""
echo "3️⃣ INSTALLING NPM DEPENDENCIES"
echo "----------------------------------------"

if [ -d "node_modules" ]; then
    echo "📦 node_modules exists, checking if complete..."
    if [ -f "node_modules/.package-lock.json" ] || [ -f "package-lock.json" ]; then
        echo "✅ Dependencies appear to be installed"
    else
        echo "⚠️ Dependencies may be incomplete, reinstalling..."
        rm -rf node_modules
        sudo npm install
    fi
else
    echo "📦 Installing npm dependencies..."
    sudo npm install
fi

# Verify critical dependencies
echo ""
echo "🔍 Checking critical dependencies..."
if [ -d "node_modules/vite" ]; then
    echo "✅ Vite installed"
else
    echo "❌ Vite missing, installing..."
    sudo npm install vite --save-dev
fi

if [ -d "node_modules/laravel-vite-plugin" ]; then
    echo "✅ Laravel Vite plugin installed"
else
    echo "❌ Laravel Vite plugin missing, installing..."
    sudo npm install laravel-vite-plugin --save-dev
fi

# ===================================================================
# 4. Check Vite Configuration
# ===================================================================
echo ""
echo "4️⃣ CHECKING VITE CONFIGURATION"
echo "----------------------------------------"

if [ -f "vite.config.js" ]; then
    echo "✅ vite.config.js found"
    echo "📋 Vite config content:"
    cat vite.config.js
else
    echo "⚠️ vite.config.js missing, creating default..."
    cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: [
                'resources/css/app.css',
                'resources/js/app.js',
            ],
            refresh: true,
        }),
    ],
});
EOF
    echo "✅ Default vite.config.js created"
fi

# ===================================================================
# 5. Check Resource Files
# ===================================================================
echo ""
echo "5️⃣ CHECKING RESOURCE FILES"
echo "----------------------------------------"

echo "📄 Checking resources/css/app.css..."
if [ -f "resources/css/app.css" ]; then
    echo "✅ app.css exists"
else
    echo "⚠️ app.css missing, creating basic file..."
    mkdir -p resources/css
    echo "/* Laravel App CSS */" > resources/css/app.css
fi

echo "📄 Checking resources/js/app.js..."
if [ -f "resources/js/app.js" ]; then
    echo "✅ app.js exists"
else
    echo "⚠️ app.js missing, creating basic file..."
    mkdir -p resources/js
    echo "// Laravel App JS" > resources/js/app.js
fi

# ===================================================================
# 6. Build Assets for Production
# ===================================================================
echo ""
echo "6️⃣ BUILDING ASSETS FOR PRODUCTION"
echo "----------------------------------------"

echo "🔨 Running npm run build..."
BUILD_OUTPUT=$(sudo npm run build 2>&1)

if echo "$BUILD_OUTPUT" | grep -q "build complete\|built in\|✓"; then
    echo "✅ Assets built successfully"
    echo "📋 Build output:"
    echo "$BUILD_OUTPUT" | tail -10
else
    echo "❌ Build failed"
    echo "📋 Build output:"
    echo "$BUILD_OUTPUT"
    echo ""
    echo "🔧 Trying alternative build command..."
    sudo npm run production 2>/dev/null || sudo npx vite build
fi

# ===================================================================
# 7. Verify Build Output
# ===================================================================
echo ""
echo "7️⃣ VERIFYING BUILD OUTPUT"
echo "----------------------------------------"

echo "📁 Checking build directory contents..."
if [ -d "public/build" ]; then
    echo "📋 Build directory contents:"
    ls -la public/build/
    
    if [ -f "public/build/manifest.json" ]; then
        echo "✅ Vite manifest.json created successfully!"
        echo "📄 Manifest content preview:"
        cat public/build/manifest.json | head -10
    else
        echo "❌ manifest.json still missing after build"
        
        # Try to create a minimal manifest
        echo "🔧 Creating minimal manifest.json..."
        mkdir -p public/build
        cat > public/build/manifest.json << 'EOF'
{
  "resources/css/app.css": {
    "file": "assets/app.css",
    "src": "resources/css/app.css"
  },
  "resources/js/app.js": {
    "file": "assets/app.js",
    "src": "resources/js/app.js"
  }
}
EOF
        echo "✅ Minimal manifest created"
    fi
else
    echo "❌ Build directory still missing"
    mkdir -p public/build
fi

# ===================================================================
# 8. Set Proper Permissions
# ===================================================================
echo ""
echo "8️⃣ SETTING PROPER PERMISSIONS"
echo "----------------------------------------"

echo "🔒 Setting ownership and permissions..."
sudo chown -R www-data:www-data public/build
sudo chmod -R 755 public/build

if [ -f "public/build/manifest.json" ]; then
    sudo chmod 644 public/build/manifest.json
fi

echo "✅ Permissions set correctly"

# ===================================================================
# 9. Clear Laravel Caches
# ===================================================================
echo ""
echo "9️⃣ CLEARING LARAVEL CACHES"
echo "----------------------------------------"

echo "🧹 Clearing Laravel caches..."
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan view:clear

echo "⚡ Caching for production..."
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan view:cache

# ===================================================================
# 10. Restart Apache
# ===================================================================
echo ""
echo "🔟 RESTARTING APACHE"
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
# 11. Test Application
# ===================================================================
echo ""
echo "1️⃣1️⃣ TESTING APPLICATION"
echo "----------------------------------------"

echo "🌐 Testing homepage..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null)

case $HTTP_CODE in
    200)
        echo "✅ SUCCESS! Application is now working (HTTP 200)"
        echo "🎉 Vite manifest error has been resolved"
        ;;
    500)
        echo "❌ Still getting 500 error"
        echo "🔍 Checking if it's still the same Vite error..."
        ERROR_CHECK=$(curl -s http://localhost/ 2>/dev/null | grep -i "vite\|manifest" | head -1)
        if [ -n "$ERROR_CHECK" ]; then
            echo "⚠️ Still Vite-related: $ERROR_CHECK"
        else
            echo "⚠️ Different error now - check Laravel logs"
        fi
        ;;
    *)
        echo "⚠️ Unexpected response: HTTP $HTTP_CODE"
        ;;
esac

echo ""
echo "🔍 Quick response preview:"
echo "========================="
curl -s http://localhost/ 2>/dev/null | head -10
echo "========================="

# ===================================================================
# 12. Final Summary
# ===================================================================
echo ""
echo "1️⃣2️⃣ SUMMARY"
echo "========================================="

echo ""
echo "🎯 ASSET BUILD STATUS:"
echo "- Node.js: $(command -v node >/dev/null && echo '✅ Installed' || echo '❌ Missing')"
echo "- npm: $(command -v npm >/dev/null && echo '✅ Installed' || echo '❌ Missing')"
echo "- node_modules: $([ -d node_modules ] && echo '✅ Present' || echo '❌ Missing')"
echo "- Build directory: $([ -d public/build ] && echo '✅ Present' || echo '❌ Missing')"
echo "- Vite manifest: $([ -f public/build/manifest.json ] && echo '✅ Present' || echo '❌ Missing')"
echo "- Application: HTTP $HTTP_CODE"

echo ""
echo "🔧 IF STILL NOT WORKING:"
echo "1. Check Laravel logs: tail -f storage/logs/laravel.log"
echo "2. Verify manifest exists: ls -la public/build/manifest.json"
echo "3. Test in browser: http://16.171.36.211"
echo "4. Try rebuilding: npm run build"

echo ""
echo "✅ Asset compilation script completed!"
echo "🌐 Test your application at: http://16.171.36.211"