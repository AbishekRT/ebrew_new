#!/bin/bash

# ===================================================================
# Fix Laravel 500 Error - Complete Environment Setup
# ===================================================================
# This script fixes the missing .env issue and sets up Laravel properly
# ===================================================================

set -e  # Exit on any error

echo "🔧 Fixing Laravel 500 Error - Setting up Environment..."
echo "================================================"

# ===================================================================
# 1. Navigate to Laravel directory
# ===================================================================
cd /var/www/html

echo "📁 Current directory: $(pwd)"
echo "📦 Checking Laravel project structure..."

if [ ! -f "artisan" ]; then
    echo "❌ This doesn't appear to be a Laravel project"
    ls -la
    exit 1
fi

echo "✅ Laravel project confirmed"

# ===================================================================
# 2. Create proper .env file with all configurations
# ===================================================================
echo "⚙️ Creating production .env file..."

sudo tee .env << 'EOF'
APP_NAME="eBrew Café"
APP_ENV=production
APP_KEY=
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

echo "✅ .env file created successfully"

# ===================================================================
# 3. Set proper ownership for .env file
# ===================================================================
sudo chown www-data:www-data .env
sudo chmod 644 .env

# ===================================================================
# 4. Generate Laravel Application Key
# ===================================================================
echo "🔑 Generating Laravel application key..."

sudo -u www-data php artisan key:generate --force

if [ $? -eq 0 ]; then
    echo "✅ Application key generated successfully"
else
    echo "❌ Failed to generate application key"
    exit 1
fi

# ===================================================================
# 5. Install MySQL and Set Up Database (if not already done)
# ===================================================================
echo "🗄️ Setting up MySQL database..."

# Check if MySQL is installed
if ! command -v mysql &> /dev/null; then
    echo "📦 Installing MySQL server..."
    sudo apt update
    sudo apt install mysql-server -y
    sudo systemctl start mysql
    sudo systemctl enable mysql
fi

# Create database and user
echo "🔧 Creating MySQL database and user..."

sudo mysql -e "CREATE DATABASE IF NOT EXISTS ebrew_laravel_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || echo "Database may already exist"
sudo mysql -e "CREATE USER IF NOT EXISTS 'ebrew_user'@'localhost' IDENTIFIED BY 'secure_db_password_2024';" 2>/dev/null || echo "User may already exist"
sudo mysql -e "GRANT ALL PRIVILEGES ON ebrew_laravel_db.* TO 'ebrew_user'@'localhost';" 2>/dev/null
sudo mysql -e "FLUSH PRIVILEGES;" 2>/dev/null

echo "✅ MySQL database setup completed"

# ===================================================================
# 6. Install Composer Dependencies (if vendor folder missing)
# ===================================================================
if [ ! -d "vendor" ]; then
    echo "📦 Installing Composer dependencies..."
    
    # Check if composer is installed
    if ! command -v composer &> /dev/null; then
        echo "🎼 Installing Composer..."
        curl -sS https://getcomposer.org/installer | php
        sudo mv composer.phar /usr/local/bin/composer
        sudo chmod +x /usr/local/bin/composer
    fi
    
    sudo -u www-data composer install --optimize-autoloader --no-dev --no-interaction
    echo "✅ Composer dependencies installed"
else
    echo "✅ Composer dependencies already installed"
fi

# ===================================================================
# 7. Run Database Migrations
# ===================================================================
echo "🗄️ Running database migrations..."

sudo -u www-data php artisan migrate --force

if [ $? -eq 0 ]; then
    echo "✅ Database migrations completed successfully"
else
    echo "⚠️ Database migrations may have issues (check logs)"
fi

# ===================================================================
# 8. Set Proper File Permissions
# ===================================================================
echo "🔒 Setting proper file permissions..."

sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type f -exec chmod 644 {} \;
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

echo "✅ File permissions set correctly"

# ===================================================================
# 9. Clear and Cache Laravel Configurations
# ===================================================================
echo "⚡ Optimizing Laravel for production..."

# Clear all caches first
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan route:clear
sudo -u www-data php artisan view:clear
sudo -u www-data php artisan cache:clear

# Cache for production
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan route:cache
sudo -u www-data php artisan view:cache

echo "✅ Laravel optimized for production"

# ===================================================================
# 10. Install MongoDB PHP Extension (if needed)
# ===================================================================
echo "🍃 Setting up MongoDB support..."

if ! php -m | grep -q mongodb; then
    echo "📦 Installing MongoDB PHP extension..."
    sudo apt install php-dev php-pear libcurl4-openssl-dev pkg-config libssl-dev -y
    sudo pecl install mongodb
    
    # Add to PHP configuration
    echo "extension=mongodb.so" | sudo tee -a /etc/php/8.4/apache2/php.ini
    echo "extension=mongodb.so" | sudo tee -a /etc/php/8.4/cli/php.ini
    
    echo "✅ MongoDB PHP extension installed"
else
    echo "✅ MongoDB PHP extension already installed"
fi

# ===================================================================
# 11. Restart Apache
# ===================================================================
echo "🔄 Restarting Apache..."

sudo systemctl restart apache2

if [ $? -eq 0 ]; then
    echo "✅ Apache restarted successfully"
else
    echo "❌ Failed to restart Apache"
    exit 1
fi

# ===================================================================
# 12. Test the Application
# ===================================================================
echo "🧪 Testing Laravel application..."

# Test if Laravel is responding
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)

case $HTTP_CODE in
    200)
        echo "✅ Laravel application is working! (HTTP 200)"
        ;;
    500)
        echo "❌ Still getting 500 error. Checking logs..."
        if [ -f "storage/logs/laravel.log" ]; then
            echo "📋 Recent Laravel errors:"
            tail -5 storage/logs/laravel.log
        fi
        ;;
    *)
        echo "⚠️ Unexpected HTTP response: $HTTP_CODE"
        ;;
esac

# ===================================================================
# 13. Final Status Report
# ===================================================================
echo ""
echo "🎉 Laravel Environment Setup Complete!"
echo "================================================"
echo ""
echo "🌐 Application URL: http://16.171.36.211"
echo "📁 Project Path: /var/www/html"
echo "🗄️ Database: ebrew_laravel_db (MySQL) + ebrew_api (MongoDB Atlas)"
echo ""
echo "🔍 Service Status:"
echo "Apache: $(systemctl is-active apache2)"
echo "MySQL: $(systemctl is-active mysql)"
echo ""
echo "📊 Application Status:"
echo "Environment: $(grep APP_ENV .env | cut -d= -f2)"
echo "Debug Mode: $(grep APP_DEBUG .env | cut -d= -f2)"
echo "Application Key: $(grep -q 'APP_KEY=base64:' .env && echo 'Set' || echo 'Not Set')"
echo ""
echo "🚨 If you still see 500 errors:"
echo "1. Check Laravel logs: tail -f storage/logs/laravel.log"
echo "2. Check Apache logs: sudo tail -f /var/log/apache2/error.log"
echo "3. Verify database connection: php artisan tinker"
echo ""
echo "✅ Setup completed! Test your application at: http://16.171.36.211"