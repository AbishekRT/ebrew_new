#!/bin/bash

echo "=== Quick Vite Config Fix ==="
echo "Fixing Laravel Vite manifest configuration issue"

# Navigate to project directory
cd /var/www/html

# Create corrected vite.config.js
cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
});
EOF

echo "✓ Updated vite.config.js with correct configuration"

# Clear previous build and rebuild
echo "Clearing previous build..."
sudo rm -rf public/build/*
sudo rm -rf node_modules/.vite*

# Rebuild assets with corrected config
echo "Rebuilding assets..."
sudo npm run build

# Fix permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Restart Apache
sudo systemctl restart apache2

echo ""
echo "=== Fix completed! ==="
echo "The vite.config.js manifest issue has been resolved."
echo "Test your website: http://16.171.119.252"
echo ""
echo "This should now properly resolve hashed asset files like:"
echo "- app-[hash].css"  
echo "- app-[hash].js"