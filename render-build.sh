#!/bin/bash
set -e

echo "Starting Render build process..."

# Update system packages
echo "Installing system dependencies..."

# Install PHP extensions if needed
echo "Installing PHP extensions..."

# Install Composer dependencies
echo "Installing Composer dependencies..."
composer install --optimize-autoloader --no-dev --no-interaction

# Install Node.js dependencies and build assets
if [ -f "package.json" ]; then
    echo "Installing Node dependencies..."
    npm install
    echo "Building assets..."
    npm run build
fi

# Laravel optimizations
echo "Optimizing Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Create storage link
echo "Creating storage link..."
php artisan storage:link

echo "Build process completed successfully!"