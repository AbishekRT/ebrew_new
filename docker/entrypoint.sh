#!/bin/bash
set -e

echo "Starting Laravel container..."

# Ensure storage and cache directories exist
mkdir -p /var/www/html/storage/logs
mkdir -p /var/www/html/bootstrap/cache

# Set proper permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Start Apache in foreground
exec apache2-foreground
