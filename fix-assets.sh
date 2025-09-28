#!/bin/bash

# Railway Asset Fix Script
# Run this after deployment to ensure assets are working

echo "=== Railway Asset Fix Script ==="

# 1. Check environment
echo "Current environment: $(php artisan env)"
echo "APP_URL: $(php artisan config:show app.url)"
echo "APP_ENV: $(php artisan config:show app.env)"

# 2. Check if assets exist
echo -e "\n=== Checking Asset Files ==="
if [ -f "public/build/manifest.json" ]; then
    echo "✅ Manifest exists"
    echo "Manifest content:"
    cat public/build/manifest.json | head -5
else
    echo "❌ Manifest missing"
fi

if [ -d "public/build/assets" ]; then
    echo "✅ Assets directory exists"
    echo "Asset files:"
    ls -la public/build/assets/ | head -10
else
    echo "❌ Assets directory missing"
fi

# 3. Clear caches to ensure fresh config
echo -e "\n=== Clearing Laravel Caches ==="
php artisan config:clear
php artisan route:clear
php artisan view:clear
echo "✅ Caches cleared"

# 4. Test asset URLs (requires APP_URL to be set correctly)
echo -e "\n=== Testing Asset URL Generation ==="
php artisan tinker --execute="
use Illuminate\Support\Facades\Vite;
try {
    echo 'CSS URL: ' . Vite::asset('resources/css/app.css') . PHP_EOL;
    echo 'JS URL: ' . Vite::asset('resources/js/app.js') . PHP_EOL;
} catch (Exception \$e) {
    echo 'Vite Error: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n=== Fix Complete ==="
echo "🔗 Test your app and check /debug/assets route"
echo "🔧 If assets still don't load, ensure APP_URL is set to your Railway domain"