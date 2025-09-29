#!/bin/bash
set -e

echo "Starting Laravel container..."

# Ensure storage and cache directories exist
mkdir -p /var/www/html/storage/logs
mkdir -p /var/www/html/bootstrap/cache

# Set proper permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Force clear all Laravel caches to ensure fresh config
echo "Clearing Laravel caches..."
php artisan config:clear || echo "Config clear failed, continuing..."
php artisan cache:clear || echo "Cache clear failed, continuing..."
php artisan view:clear || echo "View clear failed, continuing..."
php artisan route:clear || echo "Route clear failed, continuing..."

# Debug: Show database configuration
echo "Database Configuration:"
echo "DB_CONNECTION: $DB_CONNECTION"
echo "DB_HOST: $DB_HOST"
echo "DB_DATABASE: $DB_DATABASE"
echo "DATABASE_URL: ${DATABASE_URL:0:30}..." # Only show first 30 chars for security

# Test database connection
echo "Testing database connection..."
php artisan tinker --execute="echo 'DB Connection: ' . config('database.default'); echo 'Host: ' . config('database.connections.mysql.host');"

# Wait for database to be ready and run migrations
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
