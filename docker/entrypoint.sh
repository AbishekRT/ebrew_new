#!/bin/bash
set -e

cd /var/www/html

# Ensure storage & cache permissions
chown -R www-data:www-data storage bootstrap/cache
chmod -R 755 storage bootstrap/cache

# Run migrations safely (retry on failure)
until php artisan migrate --force; do
    echo "Migration failed, retrying in 5 seconds..."
    sleep 5
done

# Seed database only if environment is not production
if [ "$APP_ENV" != "production" ]; then
    php artisan db:seed --force || echo "Seeding failed or already done, skipping..."
fi

# Start Apache in the foreground
apache2-foreground
