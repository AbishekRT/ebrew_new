# Laravel Setup Commands - Run These on Your EC2 Instance

## Step 1: Connect to EC2

```bash
ssh -i "path/to/ebrew-key.pem" ubuntu@16.171.36.211
```

## Step 2: Navigate to Laravel Project

```bash
cd /var/www/html
ls -la  # Verify Laravel files are present (should see artisan file)
```

## Step 3: Remove Conflicting Files

```bash
# Remove any index.html files that might conflict
sudo rm -f public/index.html index.html
```

## Step 4: Set Up Environment File

```bash
# Copy .env file if it doesn't exist
if [ ! -f ".env" ]; then
    sudo cp .env.example .env
    echo ".env file created"
else
    echo ".env already exists"
fi
```

## Step 5: Install Composer (if not installed)

```bash
# Check if composer is installed
composer --version

# If not installed, install it:
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer
```

## Step 6: Install Dependencies

```bash
# Install Laravel dependencies
sudo -u www-data composer install --optimize-autoloader --no-dev --no-interaction
```

## Step 7: Generate Application Key

```bash
# Generate Laravel app key
sudo -u www-data php artisan key:generate --force
```

## Step 8: Set Permissions

```bash
# Set proper ownership and permissions
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type f -exec chmod 644 {} \;
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
```

## Step 9: Clear and Cache Laravel

```bash
# Clear all caches
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan route:clear
sudo -u www-data php artisan view:clear
sudo -u www-data php artisan cache:clear

# Cache for production
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan route:cache
sudo -u www-data php artisan view:cache
```

## Step 10: Verify .htaccess

```bash
# Check if .htaccess exists in public folder
ls -la public/.htaccess

# If missing, create it:
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
```

## Step 11: Test Apache Configuration

```bash
# Test Apache config
sudo apache2ctl configtest

# Restart Apache
sudo systemctl restart apache2

# Check Apache status
sudo systemctl status apache2
```

## Step 12: Final Verification

```bash
# Test PHP processing
echo "<?php phpinfo(); ?>" | sudo tee public/info.php
curl -I http://localhost/info.php
sudo rm public/info.php

# Test Laravel application
curl -I http://localhost/

# Check what's being served
curl http://localhost/ | head -20
```

## Step 13: Check Logs (if issues)

```bash
# Apache error logs
sudo tail -f /var/log/apache2/error.log

# Laravel logs
tail -f storage/logs/laravel.log

# Apache access logs
sudo tail -f /var/log/apache2/access.log
```

## Expected Results

After completing these steps:

✅ **http://16.171.36.211** should show your Laravel application (not directory listing)
✅ **No 500 errors** in browser or logs  
✅ **Laravel routing** should work properly
✅ **Assets and styles** should load correctly

## Quick Troubleshooting

### If you see "403 Forbidden":

```bash
sudo chmod 755 /var/www/html/public
sudo chown www-data:www-data /var/www/html/public/index.php
```

### If you see "500 Internal Server Error":

```bash
# Check Laravel logs
tail -20 storage/logs/laravel.log

# Check Apache logs
sudo tail -20 /var/log/apache2/error.log

# Verify .env file has APP_KEY
grep APP_KEY .env
```

### If you see directory listing:

```bash
# Verify index.php exists
ls -la public/index.php

# Check Apache virtual host
sudo apache2ctl -S
```

Run these commands one by one and let me know if you encounter any errors!
