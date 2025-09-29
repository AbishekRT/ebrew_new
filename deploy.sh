#!/bin/bash

# Railway deployment script
echo "Starting Railway deployment..."

# Install PHP dependencies
echo "Installing PHP dependencies..."
composer install --no-dev --optimize-autoloader

# Copy Railway environment file
echo "Setting up environment..."
cp .env.railway .env

# Generate application key if not set
php artisan key:generate --force

# Clear and cache configuration
echo "Optimizing application..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Run database migrations
echo "Running database migrations..."
php artisan migrate --force

# Create sessions table specifically
echo "Creating sessions table..."
php artisan migrate --path=database/migrations/2025_09_29_000000_create_sessions_table.php --force

# Build assets
echo "Building assets..."
npm ci
npm run build

# Set proper permissions
chmod -R 755 storage bootstrap/cache

echo "Deployment completed successfully!"