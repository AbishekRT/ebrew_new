#!/bin/bash

echo "Starting Apache web server..."

# Ensure basic directories exist
mkdir -p /var/www/html/storage/logs
mkdir -p /var/www/html/bootstrap/cache

# Set permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Start Apache immediately - no database operations
exec apache2-foreground