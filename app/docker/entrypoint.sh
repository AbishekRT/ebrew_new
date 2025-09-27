#!/bin/bash
set -e

# Wait for DB to be ready and run migrations safely
until php artisan migrate:fresh --seed --force; do
    echo "Migration failed, retrying in 5 seconds..."
    sleep 5
done

# Seed database only if environment is not production
if [ "$APP_ENV" != "production" ]; then
    php artisan db:seed --force || echo "Seeding failed or already done, skipping..."
fi

# Start Apache in the foreground
apache2-foreground