#!/bin/bash

# ==========================
# Laravel Production Startup
# ==========================
echo "Starting Laravel application..."

# Ensure storage directories exist and are writable
mkdir -p /var/www/html/storage/logs
mkdir -p /var/www/html/storage/framework/cache
mkdir -p /var/www/html/storage/framework/sessions
mkdir -p /var/www/html/storage/framework/views
mkdir -p /var/www/html/bootstrap/cache

# Set proper permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Clear and optimize Laravel caches
php artisan config:clear || echo "Config clear failed"
php artisan route:clear || echo "Route clear failed"
php artisan view:clear || echo "View clear failed"

# Cache configurations for production
php artisan config:cache || echo "Config cache failed"
php artisan route:cache || echo "Route cache failed"

# ==========================
# Database Migration (Non-blocking)
# ==========================
echo "Attempting database migration in background..."
{
    # Wait for database with timeout
    timeout=60
    while [ $timeout -gt 0 ]; do
        if php artisan migrate:status --no-interaction >/dev/null 2>&1; then
            echo "Database connected, running migrations..."
            php artisan migrate --force || echo "Migration failed, but continuing..."
            break
        fi
        echo "Waiting for database... ($timeout seconds remaining)"
        sleep 2
        timeout=$((timeout-2))
    done
    
    if [ $timeout -le 0 ]; then
        echo "Database connection timeout - starting without migrations"
    fi
} &

# ==========================
# Start Apache Immediately
# ==========================
echo "Starting Apache web server..."
exec apache2-foreground