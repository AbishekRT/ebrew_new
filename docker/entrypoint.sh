#!/bin/bash
set -e

echo "Starting Laravel container..."

# Ensure storage and cache directories exist
mkdir -p /var/www/html/storage/logs
mkdir -p /var/www/html/bootstrap/cache

# Set proper permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Wait for database to be ready and run migrations + seeding
until php artisan migrate --force; do
    echo "Database not ready, retrying in 5 seconds..."
    sleep 5
done

# Seed database (only if not production)
if [ "$APP_ENV" != "production" ]; then
    php artisan db:seed --force || echo "Seeding failed or already done, skipping..."
fi

# Start Apache in foreground
exec apache2-foreground
