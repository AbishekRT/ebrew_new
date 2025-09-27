#!/bin/bash

echo "🚀 Starting Railway deployment..."

# Ensure MongoDB extension is installed
echo "🔧 Ensuring MongoDB PHP extension is available..."
php -m | grep mongodb || echo "⚠️ MongoDB extension not found - Railway should install it via nixpacks.toml"

# Install PHP dependencies
echo "📦 Installing Composer dependencies..."
composer install --optimize-autoloader --no-dev --no-interaction

# Install Node dependencies if package.json exists  
if [ -f "package.json" ]; then
    echo "📦 Installing NPM dependencies..."
    npm ci --only=production
    echo "🏗️ Building assets..."
    npm run build
fi

# Generate application key if not set
if [ -z "$APP_KEY" ]; then
    echo "🔑 Generating application key..."
    php artisan key:generate --force
fi

# Clear and optimize Laravel
echo "🧹 Clearing caches..."
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "⚡ Optimizing Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Create storage directories
echo "📁 Setting up storage..."
mkdir -p storage/framework/{sessions,views,cache,testing}
mkdir -p storage/logs
mkdir -p bootstrap/cache
chmod -R 755 storage
chmod -R 755 bootstrap/cache

# Run database migrations
echo "🗄️ Running migrations..."
php artisan migrate --force

# Create storage link if not exists
if [ ! -L "public/storage" ]; then
    echo "🔗 Creating storage link..."
    php artisan storage:link
fi

echo "✅ Deployment completed successfully!"