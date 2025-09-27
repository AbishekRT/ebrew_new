#!/bin/bash
set -e

# ==========================
# Wait for Database to be Ready and Run Migrations
# ==========================
echo "Checking database connection..."
until php artisan migrate:status; do
    echo "Database not ready, retrying in 5 seconds..."
    sleep 5
done

echo "Running migrations..."
if ! php artisan migrate --force; then
    echo "Migration failed, attempting to reset and retry..."
    
    # Try to reset migrations and re-run
    php artisan migrate:reset --force || echo "Reset failed, continuing..."
    
    if ! php artisan migrate --force; then
        echo "Migration still failing, attempting fresh migration..."
        php artisan migrate:fresh --force || echo "Fresh migration failed, continuing with startup..."
    fi
fi

echo "Migrations completed or skipped"

# ==========================
# Start Apache in Foreground
# ==========================
apache2-foreground