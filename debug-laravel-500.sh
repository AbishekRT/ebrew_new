#!/bin/bash

# ===================================================================
# Laravel 500 Error Debugging Script
# ===================================================================
# Comprehensive debugging for Laravel application on EC2
# ===================================================================

set +e  # Don't exit on errors, we want to see them

echo "🔍 Laravel 500 Error Debugging Script"
echo "================================================"
echo "Time: $(date)"
echo "Server: $(hostname)"
echo ""

# ===================================================================
# 1. Basic Environment Check
# ===================================================================
echo "1️⃣ BASIC ENVIRONMENT CHECK"
echo "----------------------------------------"

cd /var/www/html || { echo "❌ Cannot access /var/www/html"; exit 1; }

echo "📁 Current directory: $(pwd)"
echo "🐘 PHP version: $(php -v | head -1)"
echo "🌐 Apache status: $(systemctl is-active apache2)"
echo "🗄️ MySQL status: $(systemctl is-active mysql)"

# Check if this is a Laravel project
if [ -f "artisan" ]; then
    echo "✅ Laravel project detected (artisan file found)"
else
    echo "❌ No artisan file found - not a Laravel project?"
    ls -la
fi

echo ""

# ===================================================================
# 2. Environment File Check
# ===================================================================
echo "2️⃣ ENVIRONMENT FILE CHECK"
echo "----------------------------------------"

if [ -f ".env" ]; then
    echo "✅ .env file exists"
    echo "📊 Key environment variables:"
    echo "APP_ENV: $(grep '^APP_ENV=' .env | cut -d= -f2)"
    echo "APP_DEBUG: $(grep '^APP_DEBUG=' .env | cut -d= -f2)"  
    echo "APP_URL: $(grep '^APP_URL=' .env | cut -d= -f2)"
    echo "DB_CONNECTION: $(grep '^DB_CONNECTION=' .env | cut -d= -f2)"
    echo "DB_HOST: $(grep '^DB_HOST=' .env | cut -d= -f2)"
    echo "DB_DATABASE: $(grep '^DB_DATABASE=' .env | cut -d= -f2)"
    echo "SESSION_DRIVER: $(grep '^SESSION_DRIVER=' .env | cut -d= -f2)"
    echo "CACHE_STORE: $(grep '^CACHE_STORE=' .env | cut -d= -f2)"
else
    echo "❌ .env file missing!"
    exit 1
fi

echo ""

# ===================================================================
# 3. Fix APP_URL for EC2
# ===================================================================
echo "3️⃣ FIXING APP_URL FOR EC2"
echo "----------------------------------------"

CURRENT_APP_URL=$(grep '^APP_URL=' .env | cut -d= -f2)
if [[ "$CURRENT_APP_URL" != "http://16.171.36.211" ]]; then
    echo "🔧 Updating APP_URL from $CURRENT_APP_URL to http://16.171.36.211"
    sudo sed -i 's|^APP_URL=.*|APP_URL=http://16.171.36.211|' .env
    echo "✅ APP_URL updated"
else
    echo "✅ APP_URL already correct"
fi

# Fix other Railway-specific URLs
if grep -q "railway.app" .env; then
    echo "🔧 Removing Railway-specific URLs..."
    sudo sed -i 's|^ASSET_URL=.*|ASSET_URL=http://16.171.36.211|' .env
    sudo sed -i 's|^SANCTUM_STATEFUL_DOMAINS=.*|SANCTUM_STATEFUL_DOMAINS=16.171.36.211|' .env
    echo "✅ Railway URLs updated"
fi

echo ""

# ===================================================================
# 4. Laravel Logs Check
# ===================================================================
echo "4️⃣ LARAVEL LOGS CHECK"
echo "----------------------------------------"

if [ -f "storage/logs/laravel.log" ]; then
    echo "📋 Last 20 lines of Laravel log:"
    echo "================================"
    tail -20 storage/logs/laravel.log
    echo "================================"
    echo ""
    
    # Check for recent errors
    RECENT_ERRORS=$(tail -50 storage/logs/laravel.log | grep -i "error\|exception\|fatal" | wc -l)
    echo "🚨 Recent errors found: $RECENT_ERRORS"
else
    echo "⚠️ No Laravel log file found at storage/logs/laravel.log"
fi

echo ""

# ===================================================================
# 5. Apache Logs Check
# ===================================================================
echo "5️⃣ APACHE LOGS CHECK"
echo "----------------------------------------"

echo "📋 Last 10 lines of Apache error log:"
echo "===================================="
sudo tail -10 /var/log/apache2/error.log 2>/dev/null || echo "Cannot read Apache error log"
echo "===================================="
echo ""

# ===================================================================
# 6. Database Connection Check
# ===================================================================
echo "6️⃣ DATABASE CONNECTION CHECK"
echo "----------------------------------------"

# Test MySQL connection from command line
DB_USER=$(grep '^DB_USERNAME=' .env | cut -d= -f2)
DB_PASS=$(grep '^DB_PASSWORD=' .env | cut -d= -f2)
DB_NAME=$(grep '^DB_DATABASE=' .env | cut -d= -f2)
DB_HOST=$(grep '^DB_HOST=' .env | cut -d= -f2)

echo "🔧 Testing MySQL connection..."
echo "Host: $DB_HOST, Database: $DB_NAME, User: $DB_USER"

if mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -e "USE $DB_NAME; SELECT 1 as test;" 2>/dev/null; then
    echo "✅ MySQL connection successful"
    
    # Check if sessions table exists
    SESSIONS_EXISTS=$(mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -D "$DB_NAME" -e "SHOW TABLES LIKE 'sessions';" 2>/dev/null | wc -l)
    if [ "$SESSIONS_EXISTS" -gt 1 ]; then
        echo "✅ Sessions table exists"
    else
        echo "⚠️ Sessions table missing - will create"
        sudo -u www-data php artisan session:table 2>/dev/null || echo "Cannot create sessions table"
    fi
else
    echo "❌ MySQL connection failed"
    echo "Trying to create database and user..."
    
    # Create database and user
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" 2>/dev/null
    sudo mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';" 2>/dev/null
    sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';" 2>/dev/null
    sudo mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
    
    # Test again
    if mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -e "USE $DB_NAME; SELECT 1;" 2>/dev/null; then
        echo "✅ MySQL connection successful after setup"
    else
        echo "❌ MySQL connection still failing"
    fi
fi

echo ""

# ===================================================================
# 7. Test Laravel Database Connection
# ===================================================================
echo "7️⃣ LARAVEL DATABASE CONNECTION TEST"
echo "----------------------------------------"

echo "🧪 Testing Laravel database connection..."
DB_TEST_RESULT=$(sudo -u www-data php artisan tinker --execute="try { \$pdo = DB::connection()->getPdo(); echo 'SUCCESS: Connected to ' . \$pdo->getAttribute(PDO::ATTR_SERVER_INFO); } catch(Exception \$e) { echo 'ERROR: ' . \$e->getMessage(); }" 2>/dev/null)

if [[ "$DB_TEST_RESULT" == *"SUCCESS"* ]]; then
    echo "✅ Laravel database connection: $DB_TEST_RESULT"
else
    echo "❌ Laravel database connection failed: $DB_TEST_RESULT"
fi

echo ""

# ===================================================================
# 8. File Permissions Check
# ===================================================================
echo "8️⃣ FILE PERMISSIONS CHECK"
echo "----------------------------------------"

echo "📁 Checking critical file permissions..."

# Check ownership
OWNER=$(stat -c %U:%G /var/www/html)
echo "Project owner: $OWNER"

# Check storage permissions
if [ -w "storage" ]; then
    echo "✅ Storage directory is writable"
else
    echo "❌ Storage directory is not writable"
    echo "🔧 Fixing storage permissions..."
    sudo chown -R www-data:www-data storage
    sudo chmod -R 775 storage
fi

# Check bootstrap/cache permissions
if [ -w "bootstrap/cache" ]; then
    echo "✅ Bootstrap/cache directory is writable"
else
    echo "❌ Bootstrap/cache directory is not writable"
    echo "🔧 Fixing bootstrap/cache permissions..."
    sudo chown -R www-data:www-data bootstrap/cache
    sudo chmod -R 775 bootstrap/cache
fi

echo ""

# ===================================================================
# 9. Clear All Caches
# ===================================================================
echo "9️⃣ CLEARING ALL CACHES"
echo "----------------------------------------"

echo "🧹 Clearing Laravel caches..."

sudo -u www-data php artisan config:clear
echo "✅ Config cache cleared"

sudo -u www-data php artisan cache:clear  
echo "✅ Application cache cleared"

sudo -u www-data php artisan route:clear
echo "✅ Route cache cleared"

sudo -u www-data php artisan view:clear
echo "✅ View cache cleared"

# Clear OPcache if available
if command -v opcache_reset &> /dev/null; then
    echo "🔧 Clearing OPcache..."
    sudo systemctl reload apache2
fi

echo ""

# ===================================================================
# 10. Run Database Migrations
# ===================================================================
echo "🔟 DATABASE MIGRATIONS"
echo "----------------------------------------"

echo "🗄️ Running database migrations..."
MIGRATION_RESULT=$(sudo -u www-data php artisan migrate --force 2>&1)

if [[ "$MIGRATION_RESULT" == *"Migrated"* ]] || [[ "$MIGRATION_RESULT" == *"Nothing to migrate"* ]]; then
    echo "✅ Database migrations successful"
else
    echo "⚠️ Migration issues: $MIGRATION_RESULT"
fi

echo ""

# ===================================================================
# 11. Asset Compilation Check
# ===================================================================
echo "1️⃣1️⃣ ASSET COMPILATION CHECK"
echo "----------------------------------------"

if [ -d "node_modules" ]; then
    echo "✅ Node modules exist"
else
    echo "⚠️ Node modules missing"
    if command -v npm &> /dev/null; then
        echo "🔧 Installing npm dependencies..."
        sudo npm install --production 2>/dev/null || echo "NPM install failed"
    else
        echo "❌ NPM not installed"
    fi
fi

# Check if assets are built
if [ -d "public/build" ]; then
    echo "✅ Built assets exist in public/build"
else
    echo "⚠️ No built assets found"
    if command -v npm &> /dev/null; then
        echo "🔧 Building assets..."
        sudo npm run build 2>/dev/null || echo "Asset build failed"
    fi
fi

echo ""

# ===================================================================
# 12. Cache for Production
# ===================================================================
echo "1️⃣2️⃣ RECACHING FOR PRODUCTION"
echo "----------------------------------------"

echo "⚡ Caching configurations..."

sudo -u www-data php artisan config:cache
echo "✅ Config cached"

sudo -u www-data php artisan route:cache  
echo "✅ Routes cached"

sudo -u www-data php artisan view:cache
echo "✅ Views cached"

echo ""

# ===================================================================
# 13. Restart Apache
# ===================================================================
echo "1️⃣3️⃣ RESTARTING APACHE"
echo "----------------------------------------"

echo "🔄 Restarting Apache..."
sudo systemctl restart apache2

if systemctl is-active --quiet apache2; then
    echo "✅ Apache restarted successfully"
else
    echo "❌ Apache failed to restart"
    sudo systemctl status apache2
fi

echo ""

# ===================================================================
# 14. Final Application Test
# ===================================================================
echo "1️⃣4️⃣ FINAL APPLICATION TEST"
echo "----------------------------------------"

echo "🌐 Testing application response..."

# Test homepage
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null)
echo "Homepage HTTP response: $HTTP_CODE"

# Test with verbose output to see actual error
echo ""
echo "🔍 Detailed response from homepage:"
echo "=================================="
RESPONSE=$(curl -s http://localhost/ 2>/dev/null | head -50)
if [[ "$RESPONSE" == *"<!DOCTYPE html>"* ]]; then
    echo "✅ HTML response received (likely working)"
elif [[ "$RESPONSE" == *"Exception"* ]] || [[ "$RESPONSE" == *"Error"* ]]; then
    echo "❌ Error response:"
    echo "$RESPONSE"
else
    echo "Response preview:"
    echo "$RESPONSE"
fi
echo "=================================="

# Test FAQ page specifically
echo ""
echo "🔍 Testing FAQ page..."
FAQ_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/faq 2>/dev/null)
echo "FAQ page HTTP response: $FAQ_CODE"

echo ""

# ===================================================================
# 15. Summary and Next Steps
# ===================================================================
echo "1️⃣5️⃣ SUMMARY AND NEXT STEPS"
echo "========================================="

echo ""
echo "🎯 DEBUGGING SUMMARY:"
echo "- Laravel project: $([ -f artisan ] && echo '✅ Confirmed' || echo '❌ Not found')"
echo "- Environment file: $([ -f .env ] && echo '✅ Present' || echo '❌ Missing')"  
echo "- Database connection: $(echo $DB_TEST_RESULT | grep -q SUCCESS && echo '✅ Working' || echo '❌ Failed')"
echo "- File permissions: $([ -w storage ] && echo '✅ OK' || echo '❌ Issues')"
echo "- Apache status: $(systemctl is-active apache2)"
echo "- Homepage response: HTTP $HTTP_CODE"

echo ""
echo "🔍 NEXT STEPS:"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Application appears to be working!"
    echo "   Test in browser: http://16.171.36.211"
elif [ "$HTTP_CODE" = "500" ]; then
    echo "❌ Still getting 500 error"
    echo "   1. Check latest Laravel logs: tail -f storage/logs/laravel.log"
    echo "   2. Enable debug mode and check detailed error"
    echo "   3. Check Apache logs: sudo tail -f /var/log/apache2/error.log"
else
    echo "⚠️ Unexpected response code: $HTTP_CODE"
    echo "   Check Apache configuration and Laravel setup"
fi

echo ""
echo "🔧 USEFUL DEBUGGING COMMANDS:"
echo "   tail -f storage/logs/laravel.log"
echo "   sudo tail -f /var/log/apache2/error.log"
echo "   php artisan route:list"
echo "   php artisan config:show database"
echo ""

echo "🎉 Debugging script completed at $(date)"