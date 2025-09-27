#!/bin/bash
set -e

echo "🔧 Running Laravel deployment steps..."

echo "📦 Installing composer dependencies..."
composer install --optimize-autoloader --no-dev --no-interaction

echo "📦 Installing npm dependencies..."
npm ci --only=production

echo "🏗️ Building assets..."
npm run build

echo "🗄️ Running database migrations..."
php artisan migrate --force

echo "🔑 Generating application key..."
php artisan key:generate --force

echo "🔗 Creating storage link..."
php artisan storage:link

echo "🚀 Starting web server..."
exec php -S 0.0.0.0:$PORT -t public/