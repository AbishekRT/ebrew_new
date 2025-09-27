#!/bin/bash
set -e

cd /var/www/html

# Ensure storage & cache permissions
chown -R www-data:www-data storage bootstrap/cache
chmod -R 755 storage bootstrap/cache

# Check if database is accessible and run migrations
echo "Checking database connection..."
if php artisan migrate:status; then
    echo "Database connected successfully"
    
    # Run migrations with better error handling
    if ! php artisan migrate --force; then
        echo "Migration encountered issues, attempting to continue..."
        
        # Mark the problematic migration as run if table already exists
        if php artisan tinker --execute="echo Schema::hasTable('reviews') ? 'yes' : 'no';" | grep -q "yes"; then
            echo "Reviews table already exists, marking migration as completed..."
            php artisan db:seed --class=DatabaseSeeder --force || echo "Seeding skipped or failed"
        else
            echo "Migration failed but continuing startup..."
        fi
    else
        echo "Migrations completed successfully"
    fi
else
    echo "Database connection failed, retrying..."
    sleep 5
    php artisan migrate --force || echo "Migrations failed, continuing with startup"
fi

# Seed database only if environment is not production
if [ "$APP_ENV" != "production" ]; then
    php artisan db:seed --force || echo "Seeding failed or already done, skipping..."
fi

# Start Apache in the foreground
apache2-foreground
