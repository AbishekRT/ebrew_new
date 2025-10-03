# Laravel Asset and Permission Fix Commands

# Run these commands one by one in your server terminal:

echo "🔧 Step 1: Fix all file ownership and permissions..."

# Fix ownership - make sure www-data owns everything

sudo chown -R www-data:www-data /var/www/html

# Fix directory permissions (755 for directories, 644 for files)

sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;

# Make specific directories writable

sudo chmod -R 775 /var/www/html/storage
sudo chmod -R 775 /var/www/html/bootstrap/cache
sudo chmod -R 775 /var/www/html/public

# Make artisan executable

sudo chmod +x /var/www/html/artisan

echo "🔧 Step 2: Clear Laravel logs and caches..."

# Remove problematic log file and recreate it

sudo rm -f /var/www/html/storage/logs/laravel.log
sudo touch /var/www/html/storage/logs/laravel.log
sudo chown www-data:www-data /var/www/html/storage/logs/laravel.log
sudo chmod 664 /var/www/html/storage/logs/laravel.log

# Clear all caches

sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan route:clear
sudo -u www-data php artisan view:clear

echo "🔧 Step 3: Create storage symlink..."

# Create storage symlink for images

sudo -u www-data php artisan storage:link

echo "🔧 Step 4: Fix Node.js and build assets..."

# Remove node_modules and package-lock if they exist with wrong permissions

sudo rm -rf /var/www/html/node_modules
sudo rm -f /var/www/html/package-lock.json

# Install as www-data user

sudo -u www-data npm install
sudo -u www-data npm run build

echo "🔧 Step 5: Final Laravel optimization..."

# Cache config as www-data

sudo -u www-data php artisan config:cache

# Restart Apache

sudo systemctl reload apache2

echo "✅ All fixes applied! Test your site now."
