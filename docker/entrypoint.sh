#!/bin/bash

echo "Starting Laravel container..."

# Ensure storage and cache directories exist
mkdir -p /var/www/html/storage/logs
mkdir -p /var/www/html/bootstrap/cache

# Set proper permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Run migrations + seed (ignore errors if DB isn’t ready yet)
echo "Running migrations and seed..."
php artisan migrate --force || true
php artisan db:seed --force || true

# Start Apache in foreground
exec apache2-foreground
