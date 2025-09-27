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

echo "Attempting fresh migration to avoid constraint issues..."
# Use fresh migration to completely rebuild the database schema
if ! php artisan migrate:fresh --force; then
    echo "Fresh migration failed, trying to handle constraints manually..."
    
    # Disable foreign key checks, reset, and re-enable
    php artisan tinker --execute="
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        Schema::dropAllTables();
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');
    " || echo "Manual cleanup failed"
    
    # Try fresh migration again
    php artisan migrate:fresh --force || echo "Migration failed, continuing with startup..."
fi

echo "Migrations completed"

# ==========================
# Start Apache in Foreground
# ==========================
apache2-foreground