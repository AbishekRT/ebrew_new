#!/bin/bash
set -e

echo "Starting application..."

# Run migrations
echo "Running database migrations..."
php artisan migrate --force

# Clear any cached config to ensure fresh start
echo "Clearing caches for production..."
php artisan config:clear
php artisan cache:clear

# Start the PHP built-in server
echo "Starting PHP server on port $PORT..."
php -S 0.0.0.0:$PORT -t public