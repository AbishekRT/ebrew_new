# Manual MongoDB Cart Analytics Deployment Guide

## 🚨 Issue Identified

Your deployment script failed due to SSH publickey permission issues. The files were never actually uploaded to the server, which is why your dashboard shows zeros.

## 🔧 Solution: Manual File Upload + SSH Fix

### Step 1: Fix SSH Connection to Your Server

#### Option A: Use Password Authentication (Quickest)

```bash
# Connect with password instead of key
scp -o PreferredAuthentications=password app/Models/CartActivityLog.php ubuntu@16.171.119.252:/var/www/html/app/Models/
```

#### Option B: Fix SSH Key (Recommended)

```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your-email@example.com"

# Copy public key to server
ssh-copy-id ubuntu@16.171.119.252

# Or manually add your public key to server's authorized_keys
cat ~/.ssh/id_ed25519.pub | ssh ubuntu@16.171.119.252 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Step 2: Manual File Upload Commands

Run these commands from your local project directory (`C:\SSP2\eBrewLaravel - Copy`):

```powershell
# Upload MongoDB Cart Analytics Files
scp app\Models\CartActivityLog.php ubuntu@16.171.119.252:/var/www/html/app/Models/
scp app\Services\CartInsightsService.php ubuntu@16.171.119.252:/var/www/html/app/Services/
scp app\Http\Controllers\DashboardController.php ubuntu@16.171.119.252:/var/www/html/app/Http/Controllers/
scp resources\views\dashboard.blade.php ubuntu@16.171.119.252:/var/www/html/resources/views/
scp routes\web.php ubuntu@16.171.119.252:/var/www/html/routes/
```

### Step 3: Set Permissions on Server

```bash
# SSH into server
ssh ubuntu@16.171.119.252

# Set proper permissions
sudo chown -R www-data:www-data /var/www/html/app/Models/CartActivityLog.php
sudo chown -R www-data:www-data /var/www/html/app/Services/CartInsightsService.php
sudo chown -R www-data:www-data /var/www/html/app/Http/Controllers/DashboardController.php
sudo chown -R www-data:www-data /var/www/html/resources/views/dashboard.blade.php
sudo chown -R www-data:www-data /var/www/html/routes/web.php

chmod 644 /var/www/html/app/Models/CartActivityLog.php
chmod 644 /var/www/html/app/Services/CartInsightsService.php
chmod 644 /var/www/html/app/Http/Controllers/DashboardController.php
chmod 644 /var/www/html/resources/views/dashboard.blade.php
chmod 644 /var/www/html/routes/web.php
```

### Step 4: Clear Laravel Cache

```bash
cd /var/www/html
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
composer dump-autoload --optimize
```

### Step 5: Test MongoDB Connection

```bash
# Test if MongoDB analytics work
php artisan tinker --execute="
try {
    \$connection = DB::connection('mongodb');
    echo 'MongoDB connection: SUCCESS\n';
    \$service = new App\Services\CartInsightsService();
    echo 'CartInsightsService loaded: SUCCESS\n';
} catch (Exception \$e) {
    echo 'Error: ' . \$e->getMessage() . '\n';
}
"
```

## 🎯 Quick Verification Steps

1. **Check if files exist on server:**

```bash
ls -la /var/www/html/app/Models/CartActivityLog.php
ls -la /var/www/html/app/Services/CartInsightsService.php
```

2. **Visit dashboard:** http://16.171.119.252/dashboard
3. **Click "Generate Test Data"** button to create sample analytics
4. **Refresh page** - you should see numbers instead of zeros

## 🔄 Alternative: Direct Server Creation

If file upload continues to fail, I can create the files directly on your server:

```bash
# SSH into server
ssh ubuntu@16.171.119.252

# Create CartActivityLog.php directly
sudo nano /var/www/html/app/Models/CartActivityLog.php
# Copy and paste the CartActivityLog.php content

# Create CartInsightsService.php directly
sudo nano /var/www/html/app/Services/CartInsightsService.php
# Copy and paste the CartInsightsService.php content

# Update DashboardController.php
sudo nano /var/www/html/app/Http/Controllers/DashboardController.php
# Add the CartInsightsService integration

# Update dashboard.blade.php
sudo nano /var/www/html/resources/views/dashboard.blade.php
# Add the cart insights section

# Update web.php
sudo nano /var/www/html/routes/web.php
# Add the test data generation route
```

Would you like me to:

1. ✅ **Help you fix the SSH connection** so you can upload files normally?
2. ✅ **Provide step-by-step manual upload commands** for each file?
3. ✅ **Create a new deployment script** that handles SSH issues better?
4. ✅ **Give you the exact file contents** to copy-paste directly on the server?
