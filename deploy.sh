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
php artisan config:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Run database migrations (sessions table already exists on Railway)
echo "Running database migrations..."
php artisan migrate --force

# Build assets (if package.json exists)
if [ -f "package.json" ]; then
    echo "Building assets..."
    npm ci --production
    npm run build
fi

# Set proper permissions
chmod -R 755 storage bootstrap/cache

echo "Deployment completed successfully!"