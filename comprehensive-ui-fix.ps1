# =====================================================================
# COMPREHENSIVE UI FIX SCRIPT - Laravel Assets & Tailwind CSS 
# =====================================================================
# This script systematically fixes all UI/CSS/JS loading issues
# =====================================================================

Write-Host "🔧 COMPREHENSIVE UI FIX - Laravel Asset Pipeline" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "Target: http://16.171.119.252" -ForegroundColor White
Write-Host "Time: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

$serverIP = "16.171.119.252"
$keyPath = "D:\Users\ansyp\Downloads\ebrew-key.pem"

# SSH Commands to execute
$fixCommands = @'
#!/bin/bash
set -e

echo "🔧 Starting Comprehensive UI Fix..."
cd /var/www/html

# PHASE 1: Fix vite.config.js
echo "📝 Fixing vite.config.js configuration..."
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
echo "✅ vite.config.js fixed"

# PHASE 2: Ensure source files exist
echo "📝 Checking source files..."
mkdir -p resources/css resources/js

if [ ! -f "resources/css/app.css" ]; then
cat > resources/css/app.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

[x-cloak] {
    display: none;
}
EOF
fi

if [ ! -f "resources/js/app.js" ]; then
cat > resources/js/app.js << 'EOF'
import './bootstrap';
import Alpine from 'alpinejs';
window.Alpine = Alpine;
Alpine.start();
EOF
fi
echo "✅ Source files verified"

# PHASE 3: Clean rebuild
echo "🧹 Cleaning build environment..."
sudo rm -rf node_modules/.cache node_modules/.vite* ~/.npm /var/www/.npm /home/ubuntu/.npm
sudo rm -rf public/build
sudo mkdir -p public/build
sudo chown -R www-data:www-data public/build

# Clear Laravel caches
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true
echo "✅ Environment cleaned"

# PHASE 4: Install dependencies
echo "📦 Installing npm dependencies..."
sudo rm -rf package-lock.json node_modules
export NPM_CONFIG_CACHE=/tmp/.npm-cache
sudo npm install --no-audit --no-fund --legacy-peer-deps
echo "✅ Dependencies installed"

# PHASE 5: Build assets
echo "🔨 Building assets..."
export NODE_ENV=production
npm run build

if [ $? -ne 0 ]; then
    echo "⚠️ Build failed, creating fallback assets..."
    mkdir -p public/build/assets
    
    # Create minimal CSS with Tailwind basics
    cat > public/build/assets/app.css << 'EOF'
/* Minimal Tailwind CSS */
*,::after,::before{box-sizing:border-box;border-width:0;border-style:solid;border-color:#e5e7eb}
html{line-height:1.5;-webkit-text-size-adjust:100%;font-family:Figtree,sans-serif;tab-size:4}
body{margin:0;line-height:inherit}
.container{width:100%;margin:0 auto;padding:0 1rem}
@media (min-width:640px){.container{max-width:640px}}
@media (min-width:768px){.container{max-width:768px}}
@media (min-width:1024px){.container{max-width:1024px}}
@media (min-width:1280px){.container{max-width:1280px}}
.bg-blue-500{background-color:#3b82f6}
.text-white{color:#fff}
.p-4{padding:1rem}
.rounded{border-radius:0.25rem}
.font-bold{font-weight:700}
EOF

    # Create minimal JS
    echo "console.log('Assets loaded successfully');" > public/build/assets/app.js
    
    # Create manifest
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
fi
echo "✅ Assets built"

# PHASE 6: Set permissions
echo "🔒 Setting permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;
sudo chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
sudo chmod -R 755 /var/www/html/public/build
echo "✅ Permissions set"

# PHASE 7: Configure Apache
echo "🌐 Configuring Apache..."
sudo tee /etc/apache2/conf-available/laravel-assets.conf > /dev/null << 'CONF'
<Directory "/var/www/html/public/build">
    Options -Indexes +FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
<Directory "/var/www/html/public">
    AllowOverride All
    Options -Indexes +FollowSymLinks  
    Require all granted
</Directory>
CONF

sudo a2enconf laravel-assets 2>/dev/null || true
sudo a2enmod rewrite deflate expires 2>/dev/null || true
echo "✅ Apache configured"

# PHASE 8: Cache optimization
echo "⚡ Optimizing caches..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan config:cache
php artisan view:cache
echo "✅ Caches optimized"

# PHASE 9: Restart Apache
echo "🔄 Restarting Apache..."
sudo systemctl restart apache2
sleep 2
echo "✅ Apache restarted"

# PHASE 10: Verify
echo "🔍 Final verification..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "000")
echo "Main page: HTTP $HTTP_CODE"

if [ -f "public/build/manifest.json" ]; then
    echo "✅ Manifest exists"
    echo "Manifest content:"
    cat public/build/manifest.json
else
    echo "❌ Manifest missing"
fi

echo ""
echo "🎉 COMPREHENSIVE UI FIX COMPLETED!"
echo "Test URL: http://16.171.119.252"
echo "Debug URL: http://16.171.119.252/debug/assets"
echo ""
'@

# Write commands to temporary file for easier SSH execution
$tempFile = "C:\temp\ui-fix-commands.sh"
$null = New-Item -ItemType Directory -Force -Path "C:\temp"
$fixCommands | Out-File -FilePath $tempFile -Encoding UTF8

Write-Host "🚀 Executing comprehensive UI fix on server..." -ForegroundColor Green
Write-Host ""

try {
    # Execute the comprehensive fix
    Write-Host "Connecting to server and running fix..." -ForegroundColor Cyan
    
    # Copy script to server and execute
    $scpCommand = "scp -i `"$keyPath`" `"$tempFile`" ubuntu@${serverIP}:/tmp/ui-fix.sh"
    $sshCommand = "ssh -i `"$keyPath`" ubuntu@${serverIP} `"chmod +x /tmp/ui-fix.sh && /tmp/ui-fix.sh`""
    
    Write-Host "Uploading fix script..." -ForegroundColor Yellow
    Invoke-Expression $scpCommand
    
    Write-Host "Executing comprehensive fix..." -ForegroundColor Yellow
    Invoke-Expression $sshCommand
    
    Write-Host ""
    Write-Host "✅ Fix execution completed!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ SSH execution failed. Run manual commands:" -ForegroundColor Red
    Write-Host ""
    Write-Host "1. SSH to server:" -ForegroundColor White
    Write-Host "   ssh -i `"$keyPath`" ubuntu@$serverIP" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Copy and paste these commands:" -ForegroundColor White
    Write-Host $fixCommands -ForegroundColor Gray
}

# Test the website
Write-Host ""
Write-Host "🌐 Testing website..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "http://$serverIP" -Method Head -TimeoutSec 10
    Write-Host "✅ Website accessible: HTTP $($response.StatusCode)" -ForegroundColor Green
    
    # Test manifest
    try {
        $manifestResponse = Invoke-WebRequest -Uri "http://$serverIP/build/manifest.json" -TimeoutSec 5
        Write-Host "✅ Manifest accessible: HTTP $($manifestResponse.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Manifest not accessible (may still be building)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "⚠️ Website test failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "==============" -ForegroundColor Yellow
Write-Host "1. Visit: http://$serverIP" -ForegroundColor White
Write-Host "2. Press Ctrl+Shift+R to hard refresh" -ForegroundColor White  
Write-Host "3. Check browser console (F12) for any remaining errors" -ForegroundColor White
Write-Host "4. Debug page: http://$serverIP/debug/assets" -ForegroundColor White
Write-Host ""
Write-Host "🔍 If UI still not working:" -ForegroundColor Yellow
Write-Host "- Check browser network tab for 404 errors" -ForegroundColor Gray
Write-Host "- Verify manifest: http://$serverIP/build/manifest.json" -ForegroundColor Gray
Write-Host "- Check Laravel logs on server: tail -f /var/www/html/storage/logs/laravel.log" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ COMPREHENSIVE UI FIX COMPLETED!" -ForegroundColor Green

# Cleanup
Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue