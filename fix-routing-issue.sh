#!/bin/bash

# Fix Laravel Routing Issues - Comprehensive Solution
# This script fixes common routing problems on EC2 Apache deployment

set -e

echo "🚀 FIXING: Laravel Routing Issues"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project path
PROJECT_PATH="/var/www/html"

echo -e "${BLUE}🔧 Step 1: Clear all Laravel caches${NC}"
cd $PROJECT_PATH
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
echo -e "${GREEN}✅ All caches cleared${NC}"

echo -e "\n${BLUE}🔄 Step 2: Rebuild optimized caches${NC}"
cd $PROJECT_PATH
php artisan config:cache
php artisan route:cache
echo -e "${GREEN}✅ Caches rebuilt${NC}"

echo -e "\n${BLUE}🌐 Step 3: Fix Apache virtual host configuration${NC}"
# Create proper Apache virtual host for Laravel
sudo tee /etc/apache2/sites-available/laravel.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName ec2-16-171-36-211.eu-north-1.compute.amazonaws.com
    DocumentRoot /var/www/html/public

    <Directory /var/www/html/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        
        # Laravel specific rewrite rules
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>

    # Handle static assets
    <Directory /var/www/html/public/build>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    
    <Directory /var/www/html/public/images>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/laravel_error.log
    CustomLog \${APACHE_LOG_DIR}/laravel_access.log combined
</VirtualHost>
EOF

echo -e "${GREEN}✅ Apache virtual host configuration updated${NC}"

echo -e "\n${BLUE}⚙️  Step 4: Enable required Apache modules${NC}"
sudo a2enmod rewrite
sudo a2enmod headers
echo -e "${GREEN}✅ Apache modules enabled${NC}"

echo -e "\n${BLUE}🔗 Step 5: Enable Laravel site and disable default${NC}"
sudo a2dissite 000-default
sudo a2ensite laravel
echo -e "${GREEN}✅ Laravel site enabled${NC}"

echo -e "\n${BLUE}🔄 Step 6: Restart Apache${NC}"
sudo systemctl restart apache2
echo -e "${GREEN}✅ Apache restarted${NC}"

echo -e "\n${BLUE}📁 Step 7: Fix file permissions${NC}"
cd $PROJECT_PATH
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
echo -e "${GREEN}✅ Permissions fixed${NC}"

echo -e "\n${BLUE}📝 Step 8: Create/update .htaccess in public directory${NC}"
cat > $PROJECT_PATH/public/.htaccess <<EOF
<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>

    RewriteEngine On

    # Handle Authorization Header
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    # Redirect Trailing Slashes If Not A Folder...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} (.+)/$
    RewriteRule ^ %1 [L,R=301]

    # Send Requests To Front Controller...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
EOF

echo -e "${GREEN}✅ .htaccess file created${NC}"

echo -e "\n${BLUE}🔍 Step 9: Verify route configuration${NC}"
cd $PROJECT_PATH
echo "Registered routes:"
php artisan route:list --columns=Method,URI,Name | head -n 15

echo -e "\n${BLUE}🎯 Step 10: Test route URL generation${NC}"
cd $PROJECT_PATH
echo "Testing route generation:"
php artisan tinker --execute="
echo 'Home: ' . route('home') . PHP_EOL;
echo 'Products: ' . route('products.index') . PHP_EOL;
echo 'FAQ: ' . route('faq') . PHP_EOL;
echo 'Login: ' . route('login') . PHP_EOL;
echo 'Register: ' . route('register') . PHP_EOL;
"

echo -e "\n${BLUE}🌐 Step 11: Test URL accessibility${NC}"
echo "Testing internal URL access:"
curl -s -o /dev/null -w "Home (200 expected): %{http_code}\n" "http://localhost/" || echo "Home URL test failed"
curl -s -o /dev/null -w "Products (200 expected): %{http_code}\n" "http://localhost/products" || echo "Products URL test failed"
curl -s -o /dev/null -w "FAQ (200 expected): %{http_code}\n" "http://localhost/faq" || echo "FAQ URL test failed"
curl -s -o /dev/null -w "Login (200 expected): %{http_code}\n" "http://localhost/login" || echo "Login URL test failed"
curl -s -o /dev/null -w "Register (200 expected): %{http_code}\n" "http://localhost/register" || echo "Register URL test failed"

echo -e "\n${BLUE}🔧 Step 12: Update APP_URL in environment${NC}"
cd $PROJECT_PATH
# Ensure APP_URL is correct
sed -i 's|APP_URL=.*|APP_URL=http://ec2-16-171-36-211.eu-north-1.compute.amazonaws.com|g' .env
echo -e "${GREEN}✅ APP_URL updated${NC}"

echo -e "\n${BLUE}♻️  Step 13: Final cache rebuild${NC}"
cd $PROJECT_PATH
php artisan config:clear
php artisan config:cache
echo -e "${GREEN}✅ Configuration refreshed${NC}"

echo -e "\n${BLUE}📊 Step 14: Check Apache status and logs${NC}"
echo "Apache status:"
systemctl status apache2 | head -n 3

echo -e "\nRecent Apache errors (if any):"
sudo tail -n 5 /var/log/apache2/error.log 2>/dev/null || echo "No recent errors"

echo -e "\n${GREEN}🏁 Routing Fix Complete!${NC}"
echo "================================="
echo -e "${YELLOW}🔍 What was fixed:${NC}"
echo "✅ Cleared all Laravel caches"
echo "✅ Rebuilt optimized caches"
echo "✅ Updated Apache virtual host with proper Laravel configuration"
echo "✅ Enabled mod_rewrite and headers modules"
echo "✅ Fixed file permissions for Laravel"
echo "✅ Created proper .htaccess file"
echo "✅ Verified route registration"
echo "✅ Updated APP_URL configuration"
echo ""
echo -e "${BLUE}🧪 Next steps:${NC}"
echo "1. Test the website: http://ec2-16-171-36-211.eu-north-1.compute.amazonaws.com"
echo "2. Try clicking each navigation link (Home, Products, FAQ, Login, Register)"
echo "3. If any issues persist, check:"
echo "   - Security groups allow HTTP traffic on port 80"
echo "   - No firewall blocking connections"
echo "   - EC2 instance has proper internet connectivity"
echo ""
echo -e "${GREEN}🎯 The routing issue should now be resolved!${NC}"