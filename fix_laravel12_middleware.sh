#!/bin/bash
set -e
cd /var/www/html

echo "=== FIXING LARAVEL 12 MIDDLEWARE ALIASES ==="
echo "Backing up current Kernel.php..."
sudo cp app/Http/Kernel.php app/Http/Kernel.php.backup.$(date +%s)

echo "Converting \$routeMiddleware to \$middlewareAliases for Laravel 12..."
# Replace $routeMiddleware with $middlewareAliases
sudo sed -i 's/protected \$routeMiddleware/protected \$middlewareAliases/g' app/Http/Kernel.php

echo "Verifying the change was made..."
grep -n "middlewareAliases" app/Http/Kernel.php || {
    echo "Failed to update to middlewareAliases - restoring backup"
    sudo cp app/Http/Kernel.php.backup.* app/Http/Kernel.php
    exit 1
}

echo "Verifying Kernel.php syntax..."
php -l app/Http/Kernel.php || {
    echo "Syntax error - restoring backup"
    sudo cp app/Http/Kernel.php.backup.* app/Http/Kernel.php
    exit 1
}

echo "Clearing ALL caches thoroughly..."
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan route:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan view:clear

echo "Regenerating autoloader..."
sudo -u www-data composer dump-autoload -o

echo "Restarting services..."
sudo systemctl restart php8.4-fpm 2>/dev/null || echo "PHP-FPM not running"
sudo systemctl restart apache2

echo "Testing admin route..."
echo "Admin route registration:"
sudo -u www-data php artisan route:list --name=admin.dashboard

echo "Testing admin middleware resolution:"
curl -s -I http://127.0.0.1/admin/dashboard | head -3

echo "Checking for any remaining errors:"
tail -5 storage/logs/laravel.log | grep -i "admin\|error" || echo "No recent admin errors found"

echo "=== FIX COMPLETED ==="
echo "Laravel 12 now uses \$middlewareAliases instead of \$routeMiddleware"