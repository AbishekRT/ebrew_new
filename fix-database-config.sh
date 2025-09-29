#!/bin/bash

# ===================================================================
# Fix Database Configuration for EC2 Deployment
# ===================================================================
# This script fixes the .env database configuration and sets up MySQL
# ===================================================================

set -e

echo "🔧 Fixing Database Configuration for EC2..."
echo "================================================"

# Navigate to Laravel directory
cd /var/www/html

# ===================================================================
# 1. Backup current .env file
# ===================================================================
echo "💾 Backing up current .env file..."
sudo cp .env .env.backup.$(date +%Y%m%d-%H%M%S)

# ===================================================================
# 2. Create correct .env file for EC2
# ===================================================================
echo "⚙️ Creating correct .env file for EC2..."

sudo tee .env << 'EOF'
APP_NAME="eBrew Café"
APP_ENV=production
APP_KEY=base64:aDUI1YE7uvxmjzym/fsIk1TRgcc3Zv4h81tCqdepuvE=
APP_DEBUG=false
APP_URL=http://16.171.36.211

APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=en_US

APP_MAINTENANCE_DRIVER=file
APP_MAINTENANCE_STORE=database

PHP_CLI_SERVER_WORKERS=4

BCRYPT_ROUNDS=12

LOG_CHANNEL=stack
LOG_STACK=single
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

# -----------------------
# MySQL Database (Local EC2)
# -----------------------
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ebrew_laravel_db
DB_USERNAME=ebrew_user
DB_PASSWORD=secure_db_password_2024

# -----------------------
# MongoDB Atlas (Cloud)
# -----------------------
MONGO_DB_CONNECTION=mongodb
MONGO_DB_URI=mongodb+srv://abhishakeshanaka_db_user:asiri123@ebrewapi.r7gfad9.mongodb.net/ebrew_api?retryWrites=true&w=majority&appName=ebrewAPI
MONGO_DB_DATABASE=ebrew_api
MONGO_DB_USERNAME=abhishakeshanaka_db_user
MONGO_DB_PASSWORD=asiri123
MONGO_DB_AUTH_DATABASE=admin

# -----------------------
# Session, Cache, Queue
# -----------------------
SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=null

CACHE_STORE=file
QUEUE_CONNECTION=database
BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local

# -----------------------
# Redis (Optional)
# -----------------------
REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

# -----------------------
# Mail Configuration
# -----------------------
MAIL_MAILER=log
MAIL_SCHEME=null
MAIL_HOST=127.0.0.1
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_FROM_ADDRESS="hello@ebrewcafe.com"
MAIL_FROM_NAME="${APP_NAME}"

# -----------------------
# Production Settings
# -----------------------
APP_TIMEZONE=UTC
SESSION_SECURE_COOKIE=false
SESSION_SAME_SITE=lax
SESSION_COOKIE=ebrew_session

# -----------------------
# Vite & Assets
# -----------------------
VITE_APP_NAME="${APP_NAME}"
EOF

echo "✅ .env file updated for EC2"

# ===================================================================
# 3. Set proper ownership
# ===================================================================
sudo chown www-data:www-data .env
sudo chmod 644 .env

# ===================================================================
# 4. Install and Configure MySQL
# ===================================================================
echo "🗄️ Setting up MySQL database..."

# Install MySQL if not present
if ! command -v mysql &> /dev/null; then
    echo "📦 Installing MySQL server..."
    sudo apt update
    sudo apt install mysql-server -y
    sudo systemctl start mysql
    sudo systemctl enable mysql
    echo "✅ MySQL installed and started"
else
    echo "✅ MySQL already installed"
fi

# Create database and user
echo "🔧 Creating database and user..."

# Create database
sudo mysql -e "CREATE DATABASE IF NOT EXISTS ebrew_laravel_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || echo "Database exists"

# Create user
sudo mysql -e "CREATE USER IF NOT EXISTS 'ebrew_user'@'localhost' IDENTIFIED BY 'secure_db_password_2024';" 2>/dev/null || echo "User exists"

# Grant privileges
sudo mysql -e "GRANT ALL PRIVILEGES ON ebrew_laravel_db.* TO 'ebrew_user'@'localhost';" 2>/dev/null

# Flush privileges
sudo mysql -e "FLUSH PRIVILEGES;" 2>/dev/null

echo "✅ Database and user configured"

# ===================================================================
# 5. Test Database Connection
# ===================================================================
echo "🧪 Testing database connection..."

if mysql -u ebrew_user -psecure_db_password_2024 -h 127.0.0.1 -e "USE ebrew_laravel_db; SELECT 1;" &>/dev/null; then
    echo "✅ MySQL connection successful"
else
    echo "❌ MySQL connection failed"
    echo "Trying to fix connection..."
    
    # Alternative user creation
    sudo mysql -e "DROP USER IF EXISTS 'ebrew_user'@'localhost';" 2>/dev/null || true
    sudo mysql -e "CREATE USER 'ebrew_user'@'localhost' IDENTIFIED BY 'secure_db_password_2024';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON ebrew_laravel_db.* TO 'ebrew_user'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    # Test again
    if mysql -u ebrew_user -psecure_db_password_2024 -h 127.0.0.1 -e "USE ebrew_laravel_db; SELECT 1;" &>/dev/null; then
        echo "✅ MySQL connection successful after retry"
    else
        echo "❌ MySQL connection still failing - check manually"
    fi
fi

# ===================================================================
# 6. Clear Laravel caches and run migrations
# ===================================================================
echo "⚡ Clearing Laravel caches..."

sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan route:clear
sudo -u www-data php artisan view:clear

echo "🗄️ Running database migrations..."
sudo -u www-data php artisan migrate --force 2>/dev/null || echo "⚠️ Migrations may have issues (check manually)"

echo "⚡ Caching for production..."
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan route:cache
sudo -u www-data php artisan view:cache

# ===================================================================
# 7. Restart Apache
# ===================================================================
echo "🔄 Restarting Apache..."
sudo systemctl restart apache2

# ===================================================================
# 8. Test Laravel Database Connection
# ===================================================================
echo "🧪 Testing Laravel database connection..."

DB_TEST=$(sudo -u www-data php artisan tinker --execute="try { DB::connection()->getPdo(); echo 'SUCCESS'; } catch(Exception \$e) { echo 'ERROR: ' . \$e->getMessage(); }" 2>/dev/null)

if [[ $DB_TEST == *"SUCCESS"* ]]; then
    echo "✅ Laravel database connection successful"
elif [[ $DB_TEST == *"ERROR"* ]]; then
    echo "❌ Laravel database connection failed: $DB_TEST"
else
    echo "⚠️ Database connection test inconclusive: $DB_TEST"
fi

# ===================================================================
# 9. Final Application Test
# ===================================================================
echo "🌐 Testing web application..."

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null)

case $HTTP_CODE in
    200)
        echo "✅ Application is working! (HTTP 200)"
        ;;
    500)
        echo "❌ Still getting 500 error"
        echo "📋 Checking recent logs..."
        if [ -f "storage/logs/laravel.log" ]; then
            echo "Latest Laravel errors:"
            tail -5 storage/logs/laravel.log 2>/dev/null || echo "No recent Laravel logs"
        fi
        ;;
    *)
        echo "⚠️ Unexpected response: HTTP $HTTP_CODE"
        ;;
esac

echo ""
echo "🎯 Final Status:"
echo "Database Host: 127.0.0.1"
echo "Database Name: ebrew_laravel_db" 
echo "Database User: ebrew_user"
echo "Application URL: http://16.171.36.211"
echo ""
echo "🔍 If still having issues, check:"
echo "1. Laravel logs: tail -f storage/logs/laravel.log"
echo "2. Apache logs: sudo tail -f /var/log/apache2/error.log"
echo "3. Test DB manually: mysql -u ebrew_user -psecure_db_password_2024 -h 127.0.0.1 ebrew_laravel_db"