#!/bin/bash

# Fix Assets and UI for Laravel Application
# This script fixes the missing CSS/JS assets issue after IP migration

echo "=== Laravel Asset Fix Script ==="
echo "Fixing UI/CSS/JS issues after elastic IP migration"

echo ""
echo "1. Fixing server permissions and clearing npm cache..."

# Fix ownership and permissions
echo "Fixing ownership and permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Clear npm cache and node_modules completely
echo "Clearing npm cache and node modules..."
sudo rm -rf /var/www/html/node_modules
sudo rm -rf /var/www/html/package-lock.json
sudo rm -rf /home/ubuntu/.npm
sudo rm -rf /var/www/.npm

# Clear any vite cache
echo "Clearing Vite cache..."
sudo rm -rf /var/www/html/public/build
sudo rm -rf /var/www/html/node_modules/.vite*

# Create fresh build directory
echo "Creating fresh build directory..."
sudo mkdir -p /var/www/html/public/build
sudo chown -R www-data:www-data /var/www/html/public/build

# Check if source files exist
echo ""
echo "2. Checking source files..."
if [ ! -f "/var/www/html/resources/css/app.css" ]; then
    echo "ERROR: resources/css/app.css not found!"
    echo "Need to upload resources directory from local machine"
    exit 1
fi

if [ ! -f "/var/www/html/resources/js/app.js" ]; then
    echo "ERROR: resources/js/app.js not found!"
    echo "Need to upload resources directory from local machine"
    exit 1
fi

echo "Source files found ✓"

# Set proper Node.js environment
export NPM_CONFIG_CACHE=/tmp/.npm
export NODE_ENV=production

# Change to web directory
cd /var/www/html

# Install dependencies with proper permissions
echo ""
echo "3. Installing npm dependencies..."
sudo -u www-data npm cache clean --force
sudo -u www-data npm install --no-audit --no-fund --production=false

if [ $? -ne 0 ]; then
    echo "NPM install failed! Trying alternative method..."
    sudo npm install --no-audit --no-fund --production=false --allow-root
fi

# Build assets
echo ""
echo "4. Building assets with Vite..."
sudo -u www-data npm run build

if [ $? -ne 0 ]; then
    echo "Build failed! Trying as root..."
    sudo npm run build --allow-root
fi

# Final permission fix
echo ""
echo "5. Final permission fixes..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Restart Apache
echo ""
echo "6. Restarting Apache..."
sudo systemctl restart apache2

echo ""
echo "=== Asset build completed! ==="
echo "Test your website: http://16.171.119.252"
echo ""
echo "If UI still not working, check:"
echo "1. http://16.171.119.252/build/manifest.json"
echo "2. Browser developer tools for 404 errors"
echo "3. /var/www/html/public/build/ directory contents"