#!/bin/sh
set -e

: "${PORT:=8080}"

cd /var/www/html

# Ensure storage & cache permissions
chown -R www-data:www-data storage bootstrap/cache
chmod -R 755 storage bootstrap/cache

# Run migrations safely (retry on failure)
if [ "${MIGRATE_ON_DEPLOY:-false}" = "true" ]; then
    until php artisan migrate --force; do
        echo "Migration failed, retrying in 5 seconds..."
        sleep 5
    done
fi

# Seed database only if environment is not production
if [ "$APP_ENV" != "production" ] && [ "${SEED_ON_DEPLOY:-false}" = "true" ]; then
    php artisan db:seed --force || echo "Seeding failed or already done, skipping..."
fi

# Start PHP built-in server in the foreground
php -S 0.0.0.0:"$PORT" -t public
