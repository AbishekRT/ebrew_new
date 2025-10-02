#!/bin/bash

echo "=== Admin 500 Error Diagnosis ==="
echo "Checking what's causing admin pages to fail..."

cd /var/www/html

# 1. Test admin user exists in correct database
echo "1. Checking admin user in correct database..."
mysql -u ebrew_user -p'secure_db_password_2024' ebrew_laravel_db -e "
SELECT id, name, email, role, is_admin 
FROM users 
WHERE email = 'abhishake.a@gmail.com';" 2>/dev/null || echo "   ❌ Admin user not found in ebrew_laravel_db"

# 2. Check if admin user exists at all
echo "2. Checking if any admin users exist..."
mysql -u ebrew_user -p'secure_db_password_2024' ebrew_laravel_db -e "
SELECT COUNT(*) as admin_count 
FROM users 
WHERE role = 'admin' OR is_admin = 1;" 2>/dev/null || echo "   ❌ Could not check admin users"

# 3. Check Laravel logs for admin-specific errors
echo "3. Checking recent Laravel errors..."
tail -20 /var/www/html/storage/logs/laravel.log | grep -A5 -B5 "admin\|Admin\|403\|middleware" || echo "   No admin-related errors found"

# 4. Test if IsAdminMiddleware file exists and is correct
echo "4. Checking IsAdminMiddleware..."
ls -la /var/www/html/app/Http/Middleware/IsAdminMiddleware.php || echo "   ❌ IsAdminMiddleware missing"

# 5. Test admin route registration
echo "5. Testing admin routes..."
php artisan route:list | grep admin | head -5

# 6. Test if we can access debug admin test
echo "6. Testing admin debug route..."
curl -s "http://localhost/debug/admin-test" | head -100 || echo "   Could not test admin debug route"

echo "=== Admin Diagnosis Complete ==="