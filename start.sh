#!/bin/bash

# Ensure storage directories exist and are writable
mkdir -p /app/storage/logs
mkdir -p /app/storage/framework/cache
mkdir -p /app/storage/framework/sessions
mkdir -p /app/storage/framework/views
chmod -R 755 /app/storage

# Ensure public/build directory exists
mkdir -p /app/public/build

# Clear and cache config (but preserve built assets)
if [ -f /app/public/build/manifest.json ]; then
    echo "Assets found, clearing config cache..."
    php artisan config:clear
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
else
    echo "No assets found, this might cause styling issues"
fi

# Start Apache in foreground
exec apache2-foreground