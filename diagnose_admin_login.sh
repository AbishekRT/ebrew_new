#!/bin/bash

echo "=== eBrew Admin Login Diagnostic ==="
echo "Checking admin login functionality..."
echo

# Check if we can connect and run basic commands
echo "1. Testing basic connectivity and Laravel status..."
cd /var/www/html

# Check if admin user exists and credentials
echo "2. Checking admin user in database..."
mysql -u root -p'mypassword' ebrew_db -e "
SELECT id, name, email, role, is_admin, email_verified_at 
FROM users 
WHERE email = 'abhishake.a@gmail.com';" 2>/dev/null || echo "Database connection failed"

# Check routes
echo "3. Testing route configuration..."
php artisan route:list | grep -E "(login|admin)" 2>/dev/null || echo "Route listing failed"

# Check for recent Laravel errors
echo "4. Checking recent Laravel errors..."
tail -10 /var/www/html/storage/logs/laravel.log 2>/dev/null || echo "No log file or permission issue"

# Test basic Laravel functionality
echo "5. Testing Laravel configuration..."
php artisan config:show auth.guards 2>/dev/null || echo "Config check failed"

# Check middleware registration
echo "6. Checking middleware registration..."
grep -n "admin.*Middleware" /var/www/html/app/Http/Kernel.php || echo "Middleware not found in Kernel"

# Check if IsAdminMiddleware exists
echo "7. Checking IsAdminMiddleware file..."
ls -la /var/www/html/app/Http/Middleware/IsAdminMiddleware.php || echo "IsAdminMiddleware file not found"

# Check current web server status
echo "8. Checking Apache status..."
systemctl status apache2 | head -5 || echo "Apache status check failed"

# Check file permissions
echo "9. Checking file permissions..."
ls -la /var/www/html/app/Http/Controllers/AuthController.php || echo "AuthController permissions issue"

echo "=== DIAGNOSTIC COMPLETE ==="
echo "Run this script to identify the exact cause of admin login issues"