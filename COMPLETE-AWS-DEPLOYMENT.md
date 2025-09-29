# 🚀 eBrew Laravel AWS Deployment - Complete Guide

## 📋 Project Summary

**Your Laravel application with dual database architecture:**

-   **Primary Database**: MySQL (for users, orders, products)
-   **Analytics Database**: MongoDB Atlas (for user analytics, favorites)
-   **Framework**: Laravel 12 with Livewire 3
-   **Target Infrastructure**: AWS EC2 Ubuntu 24.04

---

## 🎯 What You Need to Do Right Now

### 1. **On Your Local Machine (Windows)**

#### Push Updated Files to GitHub:

```powershell
# Navigate to your project directory
cd "C:\SSP2\eBrewLaravel - Copy"

# Add all updated files
git add .
git commit -m "AWS deployment with MongoDB support"
git push origin main
```

### 2. **In Your AWS Console**

#### Configure Security Group:

1. Go to **EC2 Dashboard** → **Security Groups**
2. Select your instance's security group
3. **Add these Inbound Rules**:

```
Type            Protocol    Port    Source          Description
SSH             TCP         22      0.0.0.0/0      SSH access
HTTP            TCP         80      0.0.0.0/0      Web access
HTTPS           TCP         443     0.0.0.0/0      Secure web access
MySQL/Aurora    TCP         3306    sg-xxxxx       MySQL (same security group)
```

#### (Optional) Set up Elastic IP:

1. Go to **EC2** → **Elastic IPs**
2. **Allocate Elastic IP address**
3. **Associate** with your instance `i-xxxxx`
4. Note the new IP address for later use

### 3. **On Your EC2 Instance**

#### SSH into EC2:

```bash
ssh -i "ebrew-key.pem" ubuntu@16.171.36.211
```

#### Run Deployment:

```bash
# Clone your updated repository
git clone https://github.com/AbishekRT/ebrew_new.git /tmp/ebrew-deploy
cd /tmp/ebrew-deploy

# Make the deployment script executable
chmod +x deploy-to-aws.sh

# Run the full deployment (takes 10-15 minutes)
sudo ./deploy-to-aws.sh
```

---

## 🗄️ Database Architecture Explained

### MySQL (Local on EC2)

**Purpose**: Primary relational data
**Contains**:

-   Users table
-   Products table
-   Orders and order items
-   Cart and cart items
-   Sessions
-   Laravel migrations

**Connection Details**:

```
Host: 127.0.0.1
Database: ebrew_laravel_db
Username: ebrew_user
Password: secure_db_password_2024
```

### MongoDB Atlas (Cloud)

**Purpose**: Analytics and document data
**Contains**:

-   User analytics (`UserAnalytics` model)
-   User favorites (`UserFavorites` model)
-   Product analytics (`Product` model with MongoDB)
-   Behavior tracking
-   Security events

**Connection Details**:

```
URI: mongodb+srv://abhishakeshanaka_db_user:asiri123@ebrewapi.r7gfad9.mongodb.net/ebrew_api
Database: ebrew_api
Auth Database: admin
```

---

## 🔧 What the Deployment Script Does

### System Setup:

-   ✅ Updates Ubuntu 24.04 packages
-   ✅ Installs PHP 8.2 + all required extensions
-   ✅ **Installs MongoDB PHP extension** via PECL
-   ✅ Installs Composer for dependency management
-   ✅ Installs Node.js 20 for asset compilation
-   ✅ Installs MySQL 8.0 server
-   ✅ Installs Nginx web server

### Security Configuration:

-   ✅ Configures UFW firewall
-   ✅ Secures MySQL installation
-   ✅ Sets strong database passwords
-   ✅ Configures proper file permissions

### Laravel Setup:

-   ✅ Clones from GitHub repository
-   ✅ Installs Composer dependencies (including `mongodb/laravel-mongodb`)
-   ✅ Builds assets with npm/Vite
-   ✅ **Copies `.env.aws` to `.env`** for dual database config
-   ✅ Generates application key
-   ✅ **Tests both MySQL and MongoDB connections**
-   ✅ Runs database migrations
-   ✅ Optimizes Laravel for production

### Web Server Configuration:

-   ✅ Configures Nginx virtual host
-   ✅ Sets up PHP-FPM integration
-   ✅ Creates systemd service for queue workers
-   ✅ Sets up Laravel scheduler cron job

---

## ✅ Verification Steps

### 1. Check Services Status

```bash
# All should show "active (running)"
sudo systemctl status nginx
sudo systemctl status php8.2-fpm
sudo systemctl status mysql
sudo systemctl status laravel-worker
```

### 2. Test Database Connections

```bash
# Test MySQL
php artisan tinker
# In tinker: DB::connection('mysql')->getPdo(); echo 'MySQL OK';

# Test MongoDB
# In tinker: DB::connection('mongodb')->getMongoDB(); echo 'MongoDB OK';
```

### 3. Test Web Access

```bash
# Should return HTTP 200
curl -I http://16.171.36.211

# Check specific pages
curl -s http://16.171.36.211/faq | grep -i "faq\|error"
```

### 4. Test Application Features

-   Navigate to: `http://16.171.36.211`
-   Test FAQ page: `http://16.171.36.211/faq`
-   Test registration: `http://16.171.36.211/register`
-   Check if cart counter loads properly

---

## 🚨 If Something Goes Wrong

### Check Logs:

```bash
# Laravel application logs
tail -f /var/www/ebrew/storage/logs/laravel.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log

# PHP-FPM error logs
sudo tail -f /var/log/php8.2-fpm.log

# MySQL error logs
sudo tail -f /var/log/mysql/error.log
```

### Common Fixes:

```bash
# Fix permissions
sudo chown -R ubuntu:www-data /var/www/ebrew
sudo chmod -R 755 /var/www/ebrew
sudo chmod -R 775 /var/www/ebrew/storage /var/www/ebrew/bootstrap/cache

# Clear Laravel caches
cd /var/www/ebrew
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Restart services
sudo systemctl restart nginx php8.2-fpm mysql laravel-worker
```

---

## 🔒 Security Hardening (After Basic Deployment Works)

### SSL Certificate Setup:

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# If you have a domain, get SSL certificate
sudo certbot --nginx -d yourdomain.com

# For IP-only setup, you can skip SSL for now
```

### Strengthen MySQL:

```bash
# Run MySQL secure installation
sudo mysql_secure_installation

# Set specific MySQL configurations
sudo mysql -u root -p
```

### Enable Fail2Ban:

```bash
# Install and configure Fail2Ban for SSH protection
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

---

## 📊 Performance Optimization

### Enable PHP OPcache:

```bash
# Add OPcache configuration
echo "opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=2
opcache.fast_shutdown=1" | sudo tee -a /etc/php/8.2/fpm/conf.d/10-opcache.ini

sudo systemctl restart php8.2-fpm
```

### Optimize MySQL:

```bash
# Edit MySQL configuration
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

# Add these optimizations:
# innodb_buffer_pool_size = 1G
# max_connections = 500
# query_cache_size = 64M
```

---

## 🔄 Backup & Maintenance

### Automated Backup Script:

The deployment creates a backup system at `/var/backups/ebrew/backup.sh`

### Manual Backup:

```bash
# Database backup
mysqldump -u ebrew_user -psecure_db_password_2024 ebrew_laravel_db > /tmp/mysql_backup.sql

# Files backup
tar -czf /tmp/ebrew_files.tar.gz -C /var/www ebrew --exclude='vendor' --exclude='node_modules'
```

### Regular Maintenance:

```bash
# Update system packages (monthly)
sudo apt update && sudo apt upgrade -y

# Clear old Laravel logs (weekly)
cd /var/www/ebrew
find storage/logs -name "*.log" -mtime +30 -delete

# Monitor disk space
df -h
```

---

## 🎯 Success Indicators

**Your deployment is successful when:**

✅ **Web Access**: `http://16.171.36.211` loads the Laravel welcome/home page  
✅ **FAQ Page**: `http://16.171.36.211/faq` loads without 500 errors  
✅ **Registration**: `http://16.171.36.211/register` works properly  
✅ **Database Logs**: No connection errors in Laravel logs  
✅ **Services**: All systemd services show "active (running)"  
✅ **Analytics**: MongoDB operations work (check with user registration)

---

## 📞 Emergency Support

### Quick System Check:

```bash
# Run this command to get overall system status
echo "=== eBrew System Status ===" && \
echo "Date: $(date)" && \
echo "Uptime: $(uptime)" && \
echo "Nginx: $(sudo systemctl is-active nginx)" && \
echo "PHP: $(sudo systemctl is-active php8.2-fpm)" && \
echo "MySQL: $(sudo systemctl is-active mysql)" && \
echo "Worker: $(sudo systemctl is-active laravel-worker)" && \
echo "Disk: $(df -h / | tail -1 | awk '{print $5}')" && \
echo "Memory: $(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2 }')"
```

### Reset Everything:

```bash
# If you need to start over completely
sudo systemctl stop nginx php8.2-fpm mysql laravel-worker
sudo rm -rf /var/www/ebrew
# Then re-run the deployment script
```

---

## 🎉 Next Steps After Successful Deployment

1. **Test all functionality** thoroughly
2. **Set up domain name** and SSL certificates
3. **Configure monitoring** and alerting
4. **Set up automated backups** to S3
5. **Document your specific configurations**
6. **Plan for scaling** if needed

---

**Your eBrew Laravel application with MySQL + MongoDB Atlas should now be fully operational on AWS EC2! 🚀**
