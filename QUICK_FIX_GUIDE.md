# MongoDB Cart Analytics - Quick Fix Guide

## 🚨 The Issue

Your deployment script failed due to SSH publickey permission issues. The MongoDB cart analytics files were never uploaded to your server, which is why your dashboard shows all zeros.

## ✅ Quick Solution: Manual Upload Commands

### Step 1: Upload Files Manually (Run from Windows PowerShell)

Navigate to your project directory first:

```powershell
cd "C:\SSP2\eBrewLaravel - Copy"
```

Then upload each file (when prompted for password, enter your server password):

```powershell
# Upload MongoDB Cart Analytics Files
scp -o PreferredAuthentications=password app\Models\CartActivityLog.php ubuntu@16.171.119.252:/var/www/html/app/Models/

scp -o PreferredAuthentications=password app\Services\CartInsightsService.php ubuntu@16.171.119.252:/var/www/html/app/Services/

scp -o PreferredAuthentications=password app\Http\Controllers\DashboardController.php ubuntu@16.171.119.252:/var/www/html/app/Http/Controllers/

scp -o PreferredAuthentications=password resources\views\dashboard.blade.php ubuntu@16.171.119.252:/var/www/html/resources/views/

scp -o PreferredAuthentications=password routes\web.php ubuntu@16.171.119.252:/var/www/html/routes/
```

### Step 2: SSH into Server and Set Permissions

```bash
ssh ubuntu@16.171.119.252

# Create Services directory if needed
sudo mkdir -p /var/www/html/app/Services

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

### Step 3: Clear Laravel Cache and Test

```bash
cd /var/www/html

# Clear all caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Optimize for production
php artisan config:cache
php artisan route:cache
php artisan view:cache
composer dump-autoload --optimize

# Test MongoDB connection to ebrew_api database
php artisan tinker --execute="
try {
    echo 'Testing MongoDB connection to ebrew_api...\n';
    \$connection = DB::connection('mongodb');
    echo 'MongoDB connection: SUCCESS\n';

    echo 'Testing CartActivityLog model...\n';
    \$count = App\Models\CartActivityLog::count();
    echo 'CartActivityLog accessible: SUCCESS (records: ' . \$count . ')\n';

    echo 'Testing CartInsightsService...\n';
    \$service = new App\Services\CartInsightsService();
    echo 'CartInsightsService loaded: SUCCESS\n';

} catch (Exception \$e) {
    echo 'Error: ' . \$e->getMessage() . '\n';
}
"
```

### Step 4: Test the Dashboard

1. Visit: http://16.171.119.252/dashboard
2. Login with your user account
3. Look for the "My Shopping Insights" section
4. Click "Generate Test Data" to create sample analytics
5. Refresh the page - you should see numbers instead of zeros!

## 🔧 Alternative: Direct File Creation on Server

If SCP upload still fails, create the files directly on the server:

```bash
ssh ubuntu@16.171.119.252

# Create the Services directory
sudo mkdir -p /var/www/html/app/Services

# Create CartActivityLog.php
sudo nano /var/www/html/app/Models/CartActivityLog.php
# Copy and paste the entire CartActivityLog.php content from your local file

# Create CartInsightsService.php
sudo nano /var/www/html/app/Services/CartInsightsService.php
# Copy and paste the entire CartInsightsService.php content from your local file

# Update DashboardController.php
sudo nano /var/www/html/app/Http/Controllers/DashboardController.php
# Replace with updated DashboardController.php content

# Update dashboard.blade.php
sudo nano /var/www/html/resources/views/dashboard.blade.php
# Replace with updated dashboard.blade.php content

# Update web.php
sudo nano /var/www/html/routes/web.php
# Replace with updated web.php content
```

## 📊 Verification Checklist

After uploading files, verify:

-   [ ] Files exist on server: `ls -la /var/www/html/app/Models/CartActivityLog.php`
-   [ ] Services directory created: `ls -la /var/www/html/app/Services/`
-   [ ] MongoDB connection works: Test with tinker command above
-   [ ] Dashboard loads: Visit http://16.171.119.252/dashboard
-   [ ] Can generate test data: Click the button on dashboard
-   [ ] Analytics show numbers: Refresh after generating test data

## 🎯 Expected Results

Once files are uploaded correctly:

✅ **Dashboard will show "My Shopping Insights" section**
✅ **"Generate Test Data" button will be visible**
✅ **After clicking button, analytics will show real numbers**
✅ **MongoDB ebrew_api database will contain cart_activity_logs collection**
✅ **All MySQL functionality remains untouched**

## 🚨 Still Having Issues?

If you continue to see zeros:

1. **Check Laravel logs:** `tail -f /var/www/html/storage/logs/laravel.log`
2. **Verify .env MongoDB settings** point to ebrew_api database
3. **Check MongoDB Atlas** for cart_activity_logs collection
4. **Test MongoDB connection** using the tinker command above
5. **Ensure all files uploaded** using ls commands above

The key is getting those MongoDB cart analytics files onto your server. Once they're there, the system will work perfectly! 🚀
