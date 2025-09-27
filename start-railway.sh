#!/bin/bash
set -e

echo "🚀 Railway Laravel Deployment Script Starting..."
echo "📅 $(date)"

# Wait for database to be ready
echo "⏳ Waiting for database connection..."
until php artisan migrate:status --no-interaction >/dev/null 2>&1; do
  echo "🔄 Waiting for database... (retrying in 3 seconds)"
  sleep 3
done

echo "✅ Database connection established!"

# Run migrations with force flag
echo "🗄️ Running database migrations..."
php artisan migrate --force --no-interaction

echo "🔑 Generating application key if needed..."
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "" ]; then
  php artisan key:generate --force --no-interaction
fi

echo "🔗 Creating storage symlink..."
php artisan storage:link --force --no-interaction || echo "ℹ️ Storage link already exists"

echo "🧹 Clearing application cache..."
php artisan config:clear --no-interaction
php artisan cache:clear --no-interaction
php artisan view:clear --no-interaction

echo "🏁 Starting web server..."
exec php -S 0.0.0.0:$PORT -t public/