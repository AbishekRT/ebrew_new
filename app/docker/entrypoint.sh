#!/bin/sh
set -e

# Set default port if not provided
: "${PORT:=8080}"

cd /var/www/html

# Ensure composer autoload is optimized
composer dump-autoload --optimize --no-interaction || true

# Ensure storage symlink exists
php artisan storage:link || true

# Run migrations if requested
if [ "${MIGRATE_ON_DEPLOY:-false}" = "true" ]; then
  echo "Running migrations..."
  php artisan migrate --force || { echo 'Migration failed'; exit 1; }
fi

# Start Laravel using PHP built-in server
php -S 0.0.0.0:${PORT} -t public
