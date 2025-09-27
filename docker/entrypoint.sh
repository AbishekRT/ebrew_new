#!/bin/bash
set -e

# ==========================
# Wait for Database to be Ready and Run Migrations
# ==========================
until php artisan migrate:fresh --force; do
    echo "Migration failed, retrying in 5 seconds..."
    sleep 5
done

# ==========================
# Start Apache in Foreground
# ==========================
apache2-foreground