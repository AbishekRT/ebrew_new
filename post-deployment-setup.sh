#!/bin/bash

# ===================================================================
# AWS EC2 Laravel Post-Deployment & SSL Setup Script
# ===================================================================
# Run this after the main deployment script
# This handles SSL certificates, security hardening, and monitoring
# ===================================================================

set -e

echo "🔒 Starting post-deployment security and SSL setup..."

# ===================================================================
# 1. Install Certbot for SSL Certificates
# ===================================================================
echo "🔐 Installing Certbot for SSL certificates..."
sudo apt install -y snapd
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot

# ===================================================================
# 2. Setup SSL Certificate (Let's Encrypt)
# ===================================================================
echo "📜 Setting up SSL certificate..."
echo "⚠️  Note: You need to have a domain name pointing to this IP for SSL to work"
echo "   If you have a domain, replace 'your-domain.com' in the command below"
echo ""
echo "To setup SSL with your domain, run:"
echo "sudo certbot --nginx -d your-domain.com -d www.your-domain.com"
echo ""
echo "For now, we'll configure manual SSL setup..."

# Create SSL-ready Nginx config
sudo tee /etc/nginx/sites-available/ebrew-ssl << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name 16.171.36.211 your-domain.com www.your-domain.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name 16.171.36.211 your-domain.com www.your-domain.com;
    root /var/www/ebrew/public;

    # SSL Configuration (will be auto-configured by Certbot)
    # ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    index index.php;
    charset utf-8;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
        
        # Security
        fastcgi_param HTTP_PROXY "";
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
    
    # Cache static files
    location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
    }
}
EOF

# ===================================================================
# 3. Security Hardening
# ===================================================================
echo "🛡️ Applying security hardening..."

# Configure PHP security settings
sudo tee -a /etc/php/8.2/fpm/conf.d/99-security.ini << EOF
; Security settings
expose_php = Off
display_errors = Off
display_startup_errors = Off
log_errors = On
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
allow_url_fopen = Off
allow_url_include = Off
session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 1
EOF

# Secure MySQL
sudo mysql_secure_installation --use-default

# Configure fail2ban for SSH protection
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# ===================================================================
# 4. Setup Monitoring and Logging
# ===================================================================
echo "📊 Setting up monitoring and logging..."

# Install htop for system monitoring
sudo apt install -y htop iotop

# Setup log rotation for Laravel
sudo tee /etc/logrotate.d/laravel << EOF
/var/www/ebrew/storage/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

# Create monitoring script
sudo tee /usr/local/bin/server-monitor.sh << 'EOF'
#!/bin/bash
# Simple server monitoring script

echo "=== Server Status Report - $(date) ==="
echo ""

echo "🖥️  System Load:"
uptime

echo ""
echo "💾 Memory Usage:"
free -h

echo ""
echo "💽 Disk Usage:"
df -h /

echo ""
echo "🌐 Nginx Status:"
systemctl is-active nginx

echo ""
echo "🐘 PHP-FPM Status:"
systemctl is-active php8.2-fpm

echo ""
echo "🗄️ MySQL Status:"
systemctl is-active mysql

echo ""
echo "🔄 Laravel Queue Status:"
systemctl is-active laravel-worker

echo ""
echo "🌍 Website Response:"
curl -s -o /dev/null -w "HTTP Code: %{http_code}, Response Time: %{time_total}s\n" http://localhost

echo ""
echo "📋 Recent Laravel Errors (last 10):"
tail -10 /var/www/ebrew/storage/logs/laravel.log 2>/dev/null || echo "No recent errors"

echo ""
echo "=================================="
EOF

sudo chmod +x /usr/local/bin/server-monitor.sh

# ===================================================================
# 5. Backup Configuration
# ===================================================================
echo "💾 Setting up backup configuration..."

# Create backup script
sudo tee /usr/local/bin/backup-laravel.sh << 'EOF'
#!/bin/bash
# Laravel backup script

BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)
PROJECT_DIR="/var/www/ebrew"

mkdir -p $BACKUP_DIR

echo "Creating backup for $DATE..."

# Database backup
mysqldump -u ebrew_user -psecure_db_password ebrew_laravel_db > $BACKUP_DIR/database_$DATE.sql

# File backup (excluding node_modules and vendor)
tar -czf $BACKUP_DIR/files_$DATE.tar.gz \
    --exclude='node_modules' \
    --exclude='vendor' \
    --exclude='storage/logs' \
    --exclude='storage/framework/cache' \
    --exclude='storage/framework/sessions' \
    --exclude='storage/framework/views' \
    -C /var/www ebrew

echo "Backup completed: $BACKUP_DIR"
ls -lh $BACKUP_DIR/*$DATE*

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

sudo chmod +x /usr/local/bin/backup-laravel.sh

# Setup daily backup cron job
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup-laravel.sh >> /var/log/backup.log 2>&1") | crontab -

# ===================================================================
# 6. Performance Optimization
# ===================================================================
echo "⚡ Applying performance optimizations..."

# Configure PHP-FPM for better performance
sudo tee -a /etc/php/8.2/fpm/pool.d/www.conf << EOF

; Performance settings
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.process_idle_timeout = 10s
pm.max_requests = 500
EOF

# Configure MySQL for better performance
sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf << EOF

# Performance settings
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
query_cache_type = 1
query_cache_size = 16M
EOF

# ===================================================================
# 7. Create Environment Management Scripts
# ===================================================================
echo "🔧 Creating management scripts..."

# Laravel artisan helper
sudo tee /usr/local/bin/laravel << 'EOF'
#!/bin/bash
cd /var/www/ebrew && php artisan "$@"
EOF
sudo chmod +x /usr/local/bin/laravel

# Quick restart script
sudo tee /usr/local/bin/restart-services << 'EOF'
#!/bin/bash
echo "Restarting services..."
sudo systemctl restart nginx
sudo systemctl restart php8.2-fpm
sudo systemctl restart laravel-worker
echo "Services restarted successfully!"
EOF
sudo chmod +x /usr/local/bin/restart-services

# ===================================================================
# 8. Final Restart and Status Check
# ===================================================================
echo "🔄 Final service restart..."
sudo systemctl restart php8.2-fpm
sudo systemctl restart nginx
sudo systemctl restart mysql

echo ""
echo "✅ Post-deployment setup completed!"
echo ""
echo "🔍 Service Status:"
/usr/local/bin/server-monitor.sh

echo ""
echo "🎯 Next Steps:"
echo "1. 🌐 Test your website: http://16.171.36.211"
echo "2. 🔐 Setup SSL: sudo certbot --nginx -d your-domain.com"
echo "3. 📊 Monitor server: /usr/local/bin/server-monitor.sh"
echo "4. 💾 Test backup: /usr/local/bin/backup-laravel.sh"
echo "5. 🔄 Restart services: /usr/local/bin/restart-services"
echo "6. 🎛️  Laravel commands: laravel migrate, laravel tinker, etc."
echo ""
echo "📋 Important Files:"
echo "   - Nginx config: /etc/nginx/sites-available/ebrew"
echo "   - PHP config: /etc/php/8.2/fpm/pool.d/www.conf"
echo "   - Laravel logs: /var/www/ebrew/storage/logs/laravel.log"
echo "   - Nginx logs: /var/log/nginx/error.log"
echo ""
echo "🔒 Security Notes:"
echo "   - Change default database passwords"
echo "   - Configure domain and SSL certificate"
echo "   - Review firewall rules: sudo ufw status"
echo "   - Monitor with: sudo fail2ban-client status"
echo ""
echo "🎉 Your Laravel application is now production-ready!"