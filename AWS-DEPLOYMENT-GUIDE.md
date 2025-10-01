# AWS EC2 scp -i "D:\Users\ansyp\Downloads\ebrew-key.pem" deploy-to-aws.sh ubuntu@ec2-13-60-43-49.eu-north-1.compute.amazonaws.com:~/

# Copy post-deployment script

scp -i "D:\Users\ansyp\Downloads\ebrew-key.pem" post-deployment-setup.sh ubuntu@ec2-13-60-43-49.eu-north-1.compute.amazonaws.com:~/vel Deployment Guide

## 🚀 Quick Deployment Steps

### 1. Upload Scripts to EC2

From your local machine, upload the deployment scripts:

```bash
# Upload main deployment script
scp -i "D:\Users\ansyp\Downloads\ebrew-key.pem" deploy-to-aws.sh ubuntu@ec2-13-60-43-49.eu-north-1.compute.amazonaws.com:~/

# Upload post-deployment script
scp -i "D:\Users\ansyp\Downloads\ebrew-key.pem" post-deployment-setup.sh ubuntu@ec2-13-60-43-49.eu-north-1.compute.amazonaws.com:~/
```

### 2. Connect to EC2 and Run Deployment

```bash
# SSH into your EC2 instance
ssh -i "D:\Users\ansyp\Downloads\ebrew-key.pem" ubuntu@ec2-13-60-43-49.eu-north-1.compute.amazonaws.com

# Make scripts executable
chmod +x deploy-to-aws.sh post-deployment-setup.sh

# Run main deployment (this will take 10-15 minutes)
./deploy-to-aws.sh

# Run post-deployment setup (optional but recommended)
./post-deployment-setup.sh
```

### 3. Access Your Application

Your Laravel application will be available at:

-   **HTTP**: http://13.60.43.49
-   **HTTPS**: https://13.60.43.49 (after SSL setup)

---

## 📋 What the Scripts Do

### Main Deployment Script (`deploy-to-aws.sh`)

-   ✅ Updates Ubuntu packages
-   ✅ Installs PHP 8.2 + extensions
-   ✅ Installs Composer
-   ✅ Installs Node.js for asset compilation
-   ✅ Installs MySQL server
-   ✅ Installs Nginx web server
-   ✅ Configures firewall (UFW)
-   ✅ Clones your GitHub repository
-   ✅ Installs PHP dependencies
-   ✅ Builds frontend assets
-   ✅ Creates database and user
-   ✅ Configures Laravel environment
-   ✅ Runs database migrations
-   ✅ Configures Nginx virtual host
-   ✅ Sets up Laravel queue workers
-   ✅ Optimizes Laravel for production

### Post-Deployment Script (`post-deployment-setup.sh`)

-   🔒 Installs SSL certificate support (Certbot)
-   🛡️ Security hardening
-   📊 Sets up monitoring and logging
-   💾 Configures automated backups
-   ⚡ Performance optimizations
-   🔧 Creates management scripts

---

## 🔧 Manual Configuration Required

### 1. GitHub Repository

Update the repository URL in `deploy-to-aws.sh` line ~85:

```bash
git clone https://github.com/AbishekRT/ebrew_new.git ebrew
```

### 2. Database Passwords

Change these default passwords in the script:

-   MySQL root password: `your_secure_root_password`
-   Database user password: `secure_db_password`

### 3. Environment Variables

The script creates a production `.env` file. You may need to update:

-   MongoDB connection (if used)
-   Mail settings
-   AWS S3 settings (if used)
-   Any API keys

---

## 🌐 Domain Setup (Optional)

If you have a domain name:

1. **Point your domain to the EC2 IP**:

    - Create an A record: `your-domain.com` → `13.60.43.49`
    - Create a CNAME record: `www.your-domain.com` → `your-domain.com`

2. **Setup SSL certificate**:
    ```bash
    sudo certbot --nginx -d your-domain.com -d www.your-domain.com
    ```

---

## 🔍 Troubleshooting

### Check Service Status

```bash
sudo systemctl status nginx
sudo systemctl status php8.2-fpm
sudo systemctl status mysql
```

### View Logs

```bash
# Laravel application logs
tail -f /var/www/ebrew/storage/logs/laravel.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log

# PHP-FPM logs
sudo tail -f /var/log/php8.2-fpm.log
```

### Restart Services

```bash
sudo systemctl restart nginx
sudo systemctl restart php8.2-fpm
sudo systemctl restart mysql
```

### Laravel Commands

```bash
cd /var/www/ebrew

# Clear caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Run migrations
php artisan migrate

# Check application status
php artisan about
```

---

## 📊 Monitoring Commands

### System Resources

```bash
# CPU and memory usage
htop

# Disk usage
df -h

# Active connections
sudo netstat -tulnp | grep :80
```

### Application Health

```bash
# Check website response
curl -I http://13.60.43.49

# Database connection test
mysql -u ebrew_user -p -e "SELECT 1"

# Laravel queue status
php artisan queue:work --once
```

---

## 🔒 Security Checklist

After deployment, ensure:

-   [ ] Changed default database passwords
-   [ ] Configured SSL certificate
-   [ ] Updated firewall rules if needed
-   [ ] Set up regular backups
-   [ ] Monitor server logs
-   [ ] Keep system packages updated

---

## 💡 Useful Commands

```bash
# Quick server status
/usr/local/bin/server-monitor.sh

# Restart all services
/usr/local/bin/restart-services

# Create backup
/usr/local/bin/backup-laravel.sh

# Laravel artisan shortcut
laravel migrate
laravel tinker
laravel queue:work
```

---

## 🎯 Success Indicators

Your deployment is successful when:

1. ✅ You can access http://13.60.43.49
2. ✅ Laravel welcome page or your app loads
3. ✅ Database connections work
4. ✅ No errors in `/var/www/ebrew/storage/logs/laravel.log`
5. ✅ All services show "active (running)" status

---

## 📞 Need Help?

If you encounter issues:

1. Check the logs mentioned above
2. Ensure all services are running
3. Verify firewall settings: `sudo ufw status`
4. Test database connectivity
5. Check file permissions: `ls -la /var/www/ebrew`

Happy deploying! 🚀
