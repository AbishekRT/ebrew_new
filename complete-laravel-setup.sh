#!/bin/bash

# ===================================================================
# Complete Laravel Setup Script for Ubuntu 24.04 + Apache + PHP 8.4
# ===================================================================
# Run this script on your EC2 instance to complete Laravel deployment
# ===================================================================

set -e  # Exit on any error

echo "🚀 Completing Laravel setup on Ubuntu 24.04..."
echo "================================================"

# ===================================================================
# 1. Navigate to Laravel directory and check structure
# ===================================================================
echo "📁 Checking Laravel project structure..."
cd /var/www/html

# Verify we're in a Laravel project
if [ ! -f "artisan" ]; then
    echo "❌ This doesn't appear to be a Laravel project (no artisan file found)"
    echo "Current directory contents:"
    ls -la
    exit 1
fi

echo "✅ Laravel project detected"

# ===================================================================
# 2. Remove any conflicting index.html files
# ===================================================================
echo "🧹 Removing conflicting index.html files..."
if [ -f "public/index.html" ]; then
    sudo rm public/index.html
    echo "✅ Removed public/index.html"
fi

if [ -f "index.html" ]; then
    sudo rm index.html  
    echo "✅ Removed root index.html"
fi

# ===================================================================
# 3. Set up .env file
# ===================================================================
echo "⚙️ Setting up environment configuration..."

if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        sudo cp .env.example .env
        echo "✅ Copied .env.example to .env"
    else
        echo "❌ No .env.example file found"
        exit 1
    fi
else
    echo "✅ .env file already exists"
fi

# ===================================================================
# 4. Install Composer dependencies
# ===================================================================
echo "🎼 Installing Composer dependencies..."

# Check if composer is installed
if ! command -v composer &> /dev/null; then
    echo "📦 Installing Composer..."
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    sudo chmod +x /usr/local/bin/composer
fi

# Install dependencies
sudo -u www-data composer install --optimize-autoloader --no-dev --no-interaction

if [ $? -eq 0 ]; then
    echo "✅ Composer dependencies installed successfully"
else
    echo "❌ Composer install failed"
    exit 1
fi

# ===================================================================
# 5. Generate Application Key
# ===================================================================
echo "🔑 Generating application key..."

# Check if APP_KEY is already set
if grep -q "APP_KEY=base64:" .env; then
    echo "✅ Application key already exists"
else
    sudo -u www-data php artisan key:generate --force
    echo "✅ Application key generated"
fi

# ===================================================================
# 6. Set proper file permissions
# ===================================================================
echo "🔒 Setting proper file permissions..."

# Set ownership
sudo chown -R www-data:www-data /var/www/html

# Set file permissions
sudo find /var/www/html -type f -exec chmod 644 {} \;
sudo find /var/www/html -type d -exec chmod 755 {} \;

# Set writable permissions for storage and cache
sudo chmod -R 775 /var/www/html/storage
sudo chmod -R 775 /var/www/html/bootstrap/cache

echo "✅ File permissions set correctly"

# ===================================================================
# 7. Clear and cache Laravel configurations
# ===================================================================
echo "⚡ Optimizing Laravel for production..."

# Clear all caches first
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan route:clear
sudo -u www-data php artisan view:clear
sudo -u www-data php artisan cache:clear

echo "✅ Cleared all caches"

# Cache configurations for production
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan route:cache
sudo -u www-data php artisan view:cache

echo "✅ Cached configurations for production"

# ===================================================================
# 8. Verify .htaccess file exists in public folder
# ===================================================================
echo "🔍 Checking .htaccess file..."

if [ ! -f "public/.htaccess" ]; then
    echo "📝 Creating .htaccess file..."
    sudo tee public/.htaccess << 'EOF'
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
    sudo chown www-data:www-data public/.htaccess
    sudo chmod 644 public/.htaccess
    echo "✅ .htaccess file created"
else
    echo "✅ .htaccess file already exists"
fi

# ===================================================================
# 9. Verify Apache configuration
# ===================================================================
echo "🌐 Verifying Apache configuration..."

# Test Apache configuration
sudo apache2ctl configtest

if [ $? -eq 0 ]; then
    echo "✅ Apache configuration is valid"
else
    echo "❌ Apache configuration has errors"
    exit 1
fi

# Restart Apache to ensure all changes are applied
sudo systemctl restart apache2

if [ $? -eq 0 ]; then
    echo "✅ Apache restarted successfully"
else
    echo "❌ Failed to restart Apache"
    exit 1
fi

# ===================================================================
# 10. Final verification tests
# ===================================================================
echo "🧪 Running final verification tests..."

# Check if index.php exists in public
if [ -f "public/index.php" ]; then
    echo "✅ Laravel public/index.php exists"
else
    echo "❌ Laravel public/index.php missing"
    exit 1
fi

# Test Apache status
if systemctl is-active --quiet apache2; then
    echo "✅ Apache is running"
else
    echo "❌ Apache is not running"
    exit 1
fi

# Test PHP processing
echo "<?php echo 'PHP is working'; ?>" | sudo tee /var/www/html/public/test.php > /dev/null
TEST_RESULT=$(curl -s http://localhost/test.php)
sudo rm /var/www/html/public/test.php

if [ "$TEST_RESULT" = "PHP is working" ]; then
    echo "✅ PHP is processing correctly"
else
    echo "❌ PHP is not processing correctly"
    echo "Test result: $TEST_RESULT"
fi

# Test Laravel application
echo "🔍 Testing Laravel application..."
LARAVEL_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)

if [ "$LARAVEL_TEST" = "200" ]; then
    echo "✅ Laravel application is responding (HTTP 200)"
elif [ "$LARAVEL_TEST" = "500" ]; then
    echo "⚠️ Laravel application has errors (HTTP 500)"
    echo "Checking Laravel logs..."
    if [ -f "storage/logs/laravel.log" ]; then
        echo "Recent Laravel errors:"
        tail -10 storage/logs/laravel.log
    fi
else
    echo "⚠️ Laravel application response code: $LARAVEL_TEST"
fi

# ===================================================================
# 11. Display final status and information
# ===================================================================
echo ""
echo "🎉 Laravel setup completed!"
echo "================================================"
echo ""
echo "📍 Application URL: http://16.171.36.211"
echo "📁 Project location: /var/www/html"
echo "🔧 Apache config: /etc/apache2/sites-available/ebrew.conf"
echo ""
echo "🔍 Service Status:"
echo "Apache: $(systemctl is-active apache2)"
echo "PHP version: $(php -v | head -n 1)"
echo ""
echo "📊 File Permissions:"
echo "Project owner: $(stat -c %U:%G /var/www/html)"
echo "Storage writable: $([ -w /var/www/html/storage ] && echo 'Yes' || echo 'No')"
echo "Cache writable: $([ -w /var/www/html/bootstrap/cache ] && echo 'Yes' || echo 'No')"
echo ""
echo "🚨 If you see any issues:"
echo "1. Check Apache logs: sudo tail -f /var/log/apache2/error.log"
echo "2. Check Laravel logs: tail -f /var/www/html/storage/logs/laravel.log"
echo "3. Test in browser: http://16.171.36.211"
echo ""
echo "✅ Setup complete! Your Laravel application should now be accessible."