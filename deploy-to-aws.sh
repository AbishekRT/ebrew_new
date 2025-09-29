#!/bin/bash

# ===================================================================
# AWS EC2 Laravel Deployment Script
# ===================================================================
# This script deploys a Laravel application to AWS EC2 Ubuntu 24.04
# Run this script on your EC2 instance after SSH connection
# ===================================================================

set -e  # Exit on any error

echo "🚀 Starting Laravel deployment on AWS EC2..."

# ===================================================================
# 1. Update System Packages
# ===================================================================
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# ===================================================================
# 2. Install Essential Software
# ===================================================================
echo "🔧 Installing essential software..."
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# ===================================================================
# 3. Install PHP 8.2 and Extensions (including MongoDB support)
# ===================================================================
echo "🐘 Installing PHP 8.2 and required extensions..."
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y \
    php8.2 \
    php8.2-fpm \
    php8.2-cli \
    php8.2-common \
    php8.2-mysql \
    php8.2-zip \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-curl \
    php8.2-xml \
    php8.2-bcmath \
    php8.2-json \
    php8.2-tokenizer \
    php8.2-fileinfo \
    php8.2-intl \
    php8.2-dom \
    php8.2-redis \
    php8.2-dev \
    php-pear \
    pkg-config \
    libssl-dev \
    libsasl2-dev

# Install MongoDB PHP extension
echo "📦 Installing MongoDB PHP extension..."
sudo pecl install mongodb
echo "extension=mongodb.so" | sudo tee -a /etc/php/8.2/fpm/php.ini
echo "extension=mongodb.so" | sudo tee -a /etc/php/8.2/cli/php.ini

# ===================================================================
# 4. Install Composer
# ===================================================================
echo "🎼 Installing Composer..."
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer

# ===================================================================
# 5. Install Node.js and npm (for asset compilation)
# ===================================================================
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# ===================================================================
# 6. Install MySQL Server
# ===================================================================
echo "🗄️ Installing MySQL Server..."
sudo apt install -y mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql

# Secure MySQL installation (automated)
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'your_secure_root_password';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -e "FLUSH PRIVILEGES;"

# ===================================================================
# 7. Install Nginx
# ===================================================================
echo "🌐 Installing Nginx..."
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# ===================================================================
# 8. Configure Firewall
# ===================================================================
echo "🔥 Configuring UFW firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 80
sudo ufw allow 443

# ===================================================================
# 9. Create Project Directory and Set Permissions
# ===================================================================
echo "📁 Setting up project directory..."
sudo mkdir -p /var/www/ebrew
sudo chown -R ubuntu:ubuntu /var/www/ebrew
cd /var/www

# ===================================================================
# 10. Clone Project from GitHub
# ===================================================================
echo "📥 Cloning project from GitHub..."
# You'll need to replace this with your actual GitHub repository
git clone https://github.com/AbishekRT/ebrew_new.git ebrew
cd ebrew

# Set proper ownership
sudo chown -R ubuntu:www-data /var/www/ebrew
sudo chmod -R 755 /var/www/ebrew
sudo chmod -R 775 /var/www/ebrew/storage
sudo chmod -R 775 /var/www/ebrew/bootstrap/cache

# ===================================================================
# 11. Install PHP Dependencies
# ===================================================================
echo "🎼 Installing Composer dependencies..."
composer install --optimize-autoloader --no-dev

# ===================================================================
# 12. Install Node.js Dependencies and Build Assets
# ===================================================================
echo "📦 Installing npm dependencies and building assets..."
npm install
npm run build

# ===================================================================
# 13. Configure Environment (with MongoDB + MySQL support)
# ===================================================================
echo "⚙️ Configuring environment for dual database setup..."

# Copy the AWS-specific environment file
if [ -f ".env.aws" ]; then
    cp .env.aws .env
    echo "✅ Used .env.aws configuration"
else
    cp .env.example .env
    echo "⚠️ Using .env.example as fallback"
fi

# Generate application key
php artisan key:generate --force

# ===================================================================
# 14. Create Database
# ===================================================================
echo "🗄️ Setting up database..."
sudo mysql -u root -pyour_secure_root_password -e "CREATE DATABASE IF NOT EXISTS ebrew_laravel_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -u root -pyour_secure_root_password -e "CREATE USER IF NOT EXISTS 'ebrew_user'@'localhost' IDENTIFIED BY 'secure_db_password_2024';"
sudo mysql -u root -pyour_secure_root_password -e "GRANT ALL PRIVILEGES ON ebrew_laravel_db.* TO 'ebrew_user'@'localhost';"
sudo mysql -u root -pyour_secure_root_password -e "FLUSH PRIVILEGES;"

# ===================================================================
# 15. Update Environment with AWS-specific Database Credentials
# ===================================================================
echo "⚙️ Updating environment with secure database credentials..."

# Update database password in .env file
sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=secure_db_password_2024/' .env

# Ensure MongoDB configuration is present
if ! grep -q "MONGO_DB_URI" .env; then
    echo "" >> .env
    echo "# MongoDB Atlas Configuration" >> .env
    echo "MONGO_DB_URI=mongodb+srv://abhishakeshanaka_db_user:asiri123@ebrewapi.r7gfad9.mongodb.net/ebrew_api" >> .env
    echo "MONGO_DB_DATABASE=ebrew_api" >> .env
    echo "MONGO_DB_AUTH_DATABASE=admin" >> .env
fi

# Generate new app key if not present
if ! grep -q "APP_KEY=" .env || grep -q "APP_KEY=$" .env; then
    php artisan key:generate --force
fi

# ===================================================================
# 16. Test Database Connections and Run Migrations
# ===================================================================
echo "🗄️ Testing database connections..."

# Test MySQL connection
echo "Testing MySQL connection..."
if php artisan tinker --execute="DB::connection('mysql')->getPdo(); echo 'MySQL Connected Successfully';" 2>/dev/null; then
    echo "✅ MySQL connection successful"
else
    echo "❌ MySQL connection failed"
    exit 1
fi

# Test MongoDB connection
echo "Testing MongoDB connection..."
if php artisan tinker --execute="DB::connection('mongodb')->getMongoDB(); echo 'MongoDB Connected Successfully';" 2>/dev/null; then
    echo "✅ MongoDB connection successful"
else
    echo "⚠️ MongoDB connection failed - will continue with MySQL only"
fi

# Run database migrations
echo "🗄️ Running database migrations..."
php artisan migrate --force

# ===================================================================
# 17. Configure Nginx Virtual Host
# ===================================================================
echo "🌐 Configuring Nginx virtual host..."
sudo tee /etc/nginx/sites-available/ebrew << EOF
server {
    listen 80;
    listen [::]:80;
    server_name 16.171.36.211;
    root /var/www/ebrew/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/ebrew /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# ===================================================================
# 18. Configure PHP-FPM
# ===================================================================
echo "🐘 Configuring PHP-FPM..."
sudo sed -i 's/user = www-data/user = ubuntu/' /etc/php/8.2/fpm/pool.d/www.conf
sudo sed -i 's/group = www-data/group = www-data/' /etc/php/8.2/fpm/pool.d/www.conf

# ===================================================================
# 19. Set Final Permissions
# ===================================================================
echo "🔒 Setting final permissions..."
sudo chown -R ubuntu:www-data /var/www/ebrew
sudo chmod -R 755 /var/www/ebrew
sudo chmod -R 775 /var/www/ebrew/storage
sudo chmod -R 775 /var/www/ebrew/bootstrap/cache

# ===================================================================
# 20. Create Systemd Service for Queue Workers (Optional)
# ===================================================================
echo "⚡ Creating Laravel queue worker service..."
sudo tee /etc/systemd/system/laravel-worker.service << EOF
[Unit]
Description=Laravel queue worker
After=network.target

[Service]
User=ubuntu
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/ebrew/artisan queue:work --sleep=3 --tries=3 --max-time=3600
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable laravel-worker
sudo systemctl start laravel-worker

# ===================================================================
# 21. Restart Services
# ===================================================================
echo "🔄 Restarting services..."
sudo systemctl restart php8.2-fpm
sudo systemctl restart nginx

# ===================================================================
# 22. Configure Laravel Scheduler (Cron)
# ===================================================================
echo "⏰ Setting up Laravel scheduler..."
(crontab -l 2>/dev/null; echo "* * * * * cd /var/www/ebrew && php artisan schedule:run >> /dev/null 2>&1") | crontab -

# ===================================================================
# 23. Optimize Laravel for Production
# ===================================================================
echo "⚡ Optimizing Laravel for production..."
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# ===================================================================
# 24. Final Status Check
# ===================================================================
echo "✅ Deployment completed! Checking service status..."
echo ""
echo "🔍 Service Status:"
sudo systemctl status nginx --no-pager -l
sudo systemctl status php8.2-fpm --no-pager -l
sudo systemctl status mysql --no-pager -l

echo ""
echo "🌐 Your Laravel application should now be accessible at:"
echo "   http://16.171.36.211"
echo ""
echo "📋 Important Information:"
echo "   - MySQL root password: your_secure_root_password"
echo "   - Database: ebrew_laravel_db"
echo "   - Database user: ebrew_user"
echo "   - Database password: secure_db_password_2024"
echo "   - MongoDB Atlas: ebrew_api database"
echo "   - Project location: /var/www/ebrew"
echo ""
echo "🔧 Useful commands:"
echo "   - View logs: sudo tail -f /var/log/nginx/error.log"
echo "   - Laravel logs: tail -f /var/www/ebrew/storage/logs/laravel.log"
echo "   - Restart services: sudo systemctl restart nginx php8.2-fpm"
echo ""
echo "⚠️  Remember to:"
echo "   1. Change default passwords"
echo "   2. Set up SSL certificates (Let's Encrypt)"
echo "   3. Configure proper backup strategy"
echo "   4. Monitor server resources"

echo "🎉 Deployment script completed successfully!"