Write-Host "🎯 TARGETED UI FIX - Based on Debugging" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow
Write-Host ""

$serverIP = "16.171.119.252"
$keyPath = "D:\Users\ansyp\Downloads\ebrew-key.pem"

Write-Host "The comprehensive script worked (assets built successfully)" -ForegroundColor Green
Write-Host "But UI still not showing. This means the issue is:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Laravel can't resolve asset URLs from manifest" -ForegroundColor White
Write-Host "2. Assets exist but Apache can't serve them" -ForegroundColor White  
Write-Host "3. Missing dependencies (bootstrap.js)" -ForegroundColor White
Write-Host "4. .htaccess or permission issues" -ForegroundColor White
Write-Host ""

Write-Host "🚀 Running targeted diagnostic and fix..." -ForegroundColor Cyan

$targetedFix = @'
#!/bin/bash
cd /var/www/html

echo "🎯 TARGETED UI FIX - Debugging Asset Resolution"
echo "=============================================="

# 1. Test Laravel Vite asset URL generation  
echo "1️⃣ Testing asset URL generation..."
php artisan tinker --execute="
use Illuminate\\Support\\Facades\\Vite;
echo 'APP_URL: ' . config('app.url') . PHP_EOL;
try {
    echo 'CSS URL: ' . Vite::asset('resources/css/app.css') . PHP_EOL;
    echo 'JS URL: ' . Vite::asset('resources/js/app.js') . PHP_EOL;
} catch (Exception \$e) {
    echo 'ERROR: ' . \$e->getMessage() . PHP_EOL;
}
"

# 2. Check if bootstrap.js exists (common cause of build issues)
echo ""
echo "2️⃣ Checking bootstrap.js dependency..."
if [ ! -f "resources/js/bootstrap.js" ]; then
    echo "❌ Missing bootstrap.js - creating it..."
    cat > resources/js/bootstrap.js << 'EOF'
import axios from 'axios';
window.axios = axios;
window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';
let token = document.head.querySelector('meta[name="csrf-token"]');
if (token) {
    window.axios.defaults.headers.common['X-CSRF-TOKEN'] = token.content;
}
EOF
    echo "✅ bootstrap.js created"
else
    echo "✅ bootstrap.js exists"
fi

# 3. Check .htaccess
echo ""
echo "3️⃣ Checking .htaccess..."
if [ ! -f "public/.htaccess" ]; then
    echo "❌ Missing .htaccess - creating Laravel default..."
    cat > public/.htaccess << 'EOF'
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
EOF
    echo "✅ .htaccess created"
fi

# 4. Rebuild assets
echo ""
echo "4️⃣ Rebuilding assets..."
rm -rf public/build/* node_modules/.vite*
npm run build

# 5. Test HTTP access to assets
echo ""
echo "5️⃣ Testing HTTP access..."
if [ -f public/build/manifest.json ]; then
    MANIFEST_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/build/manifest.json)
    echo "Manifest HTTP: $MANIFEST_CODE"
fi

if ls public/build/assets/app-*.css &>/dev/null; then
    CSS_FILE=$(ls public/build/assets/app-*.css | head -1 | sed 's|public/||')
    CSS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/$CSS_FILE")
    echo "CSS HTTP: $CSS_CODE"
fi

# 6. Clear Laravel caches
echo ""
echo "6️⃣ Clearing caches..."
php artisan config:clear
php artisan view:clear
php artisan cache:clear

# 7. Fix permissions
echo ""
echo "7️⃣ Setting permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# 8. Restart Apache
echo ""
echo "8️⃣ Restarting Apache..."
systemctl restart apache2

echo ""
echo "✅ TARGETED FIX COMPLETED"
echo "========================"
echo ""
echo "🔍 CRITICAL: Visit this debug page to see what's happening:"
echo "👉 http://16.171.119.252/debug/assets"
echo ""
echo "This page will show:"
echo "• What URLs Laravel is generating for CSS/JS" 
echo "• Whether assets actually exist"
echo "• What the manifest contains"
echo ""
'@

try {
    Write-Host "Uploading and executing targeted fix..." -ForegroundColor Cyan
    
    # Create temp file
    $tempFile = "C:\temp\targeted-ui-fix.sh"  
    $null = New-Item -ItemType Directory -Force -Path "C:\temp"
    $targetedFix | Out-File -FilePath $tempFile -Encoding UTF8

    # Upload and execute
    $scpCommand = "scp -i `"$keyPath`" `"$tempFile`" ubuntu@${serverIP}:/tmp/"
    $sshCommand = "ssh -i `"$keyPath`" ubuntu@${serverIP} `"chmod +x /tmp/targeted-ui-fix.sh && sudo /tmp/targeted-ui-fix.sh`""
    
    Invoke-Expression $scpCommand
    Invoke-Expression $sshCommand
    
    Write-Host ""
    Write-Host "✅ Targeted fix executed!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ SSH failed. Manual execution required:" -ForegroundColor Red
    Write-Host ""
    Write-Host "SSH Command:" -ForegroundColor White
    Write-Host "ssh -i `"$keyPath`" ubuntu@$serverIP" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Then run:" -ForegroundColor White  
    Write-Host $targetedFix -ForegroundColor Gray
}

Write-Host ""
Write-Host "🎯 NEXT: VISIT THE DEBUG PAGE" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Yellow
Write-Host ""
Write-Host "👉 http://$serverIP/debug/assets" -ForegroundColor White
Write-Host ""
Write-Host "This page will show exactly:" -ForegroundColor Cyan
Write-Host "• What asset URLs Laravel is generating" -ForegroundColor White
Write-Host "• Whether the manifest file is correct" -ForegroundColor White
Write-Host "• If Tailwind CSS classes are working" -ForegroundColor White
Write-Host "• JavaScript console information" -ForegroundColor White
Write-Host ""
Write-Host "🔍 Look for:" -ForegroundColor Yellow
Write-Host "• 'Vite Error' messages" -ForegroundColor Gray
Write-Host "• Wrong asset URLs (should point to /build/assets/)" -ForegroundColor Gray  
Write-Host "• Missing or empty CSS/JS files" -ForegroundColor Gray
Write-Host ""
Write-Host "Based on the debug page, we'll know exactly what to fix!" -ForegroundColor Green

# Cleanup
Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue