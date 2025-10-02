#!/bin/bash

echo "=== Debug Admin Login Issues ==="
echo "Checking why admin login is failing..."

cd /var/www/html

# 1. Check what admin users actually exist in the database
echo "1. Checking existing admin users in database..."
mysql -u root ebrew_laravel_db -e "
SELECT id, name, email, role, is_admin, password 
FROM users 
WHERE role = 'admin' OR is_admin = 1 
ORDER BY id;" 2>/dev/null || echo "Could not check admin users"

# 2. Check if the specific admin emails exist
echo "2. Checking specific admin emails..."
echo "   Checking abhishake.a@gmail.com..."
mysql -u root ebrew_laravel_db -e "
SELECT id, name, email, role, is_admin 
FROM users 
WHERE email = 'abhishake.a@gmail.com';" 2>/dev/null || echo "Could not find abhishake.a@gmail.com"

echo "   Checking prageeshaa@admin.ebrew.com..."
mysql -u root ebrew_laravel_db -e "
SELECT id, name, email, role, is_admin 
FROM users 
WHERE email = 'prageeshaa@admin.ebrew.com';" 2>/dev/null || echo "Could not find prageeshaa@admin.ebrew.com"

# 3. Test password hashes
echo "3. Testing password hashes..."
echo "   Testing 'password' hash..."
php -r "echo 'Password hash test: ' . (password_verify('password', '\$2y\$12\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi') ? 'VALID' : 'INVALID') . PHP_EOL;"

echo "   Testing 'asiri12345' hash..."
php -r "
\$hash = password_hash('asiri12345', PASSWORD_DEFAULT);
echo 'asiri12345 new hash: ' . \$hash . PHP_EOL;
"

# 4. Check IsAdminMiddleware
echo "4. Checking IsAdminMiddleware..."
if [ -f "app/Http/Middleware/IsAdminMiddleware.php" ]; then
    echo "   ✅ IsAdminMiddleware exists"
    grep -n "isAdmin" app/Http/Middleware/IsAdminMiddleware.php || echo "   No isAdmin method found"
else
    echo "   ❌ IsAdminMiddleware missing"
fi

# 5. Check User model isAdmin method
echo "5. Checking User model isAdmin method..."
grep -A 5 "function isAdmin" app/Models/User.php || echo "   No isAdmin method found in User model"

# 6. Check recent Laravel errors
echo "6. Checking recent Laravel errors..."
tail -20 /var/www/html/storage/logs/laravel.log | grep -E "(ERROR|Exception|admin|Admin)" | tail -5 || echo "No recent admin-related errors"

# 7. Test customer vs admin authentication
echo "7. Testing authentication logic..."
php artisan tinker --execute="
try {
    // Test customer user
    \$customer = \App\Models\User::where('role', 'customer')->first();
    if (\$customer) {
        echo 'Customer found: ' . \$customer->email . ' | Role: ' . \$customer->role . ' | isAdmin: ' . (\$customer->isAdmin() ? 'true' : 'false') . PHP_EOL;
    }
    
    // Test admin user
    \$admin = \App\Models\User::where('email', 'abhishake.a@gmail.com')->first();
    if (\$admin) {
        echo 'Admin found: ' . \$admin->email . ' | Role: ' . \$admin->role . ' | is_admin field: ' . \$admin->is_admin . ' | isAdmin method: ' . (\$admin->isAdmin() ? 'true' : 'false') . PHP_EOL;
    } else {
        echo 'Admin user abhishake.a@gmail.com not found' . PHP_EOL;
    }
    
    // Test other admin
    \$admin2 = \App\Models\User::where('email', 'prageeshaa@admin.ebrew.com')->first();
    if (\$admin2) {
        echo 'Admin2 found: ' . \$admin2->email . ' | Role: ' . \$admin2->role . ' | is_admin field: ' . \$admin2->is_admin . ' | isAdmin method: ' . (\$admin2->isAdmin() ? 'true' : 'false') . PHP_EOL;
    } else {
        echo 'Admin user prageeshaa@admin.ebrew.com not found' . PHP_EOL;
    }
} catch (Exception \$e) {
    echo 'Error: ' . \$e->getMessage() . PHP_EOL;
}
exit;
" 2>/dev/null || echo "Authentication test failed"

echo
echo "=== Debug Complete ==="
echo "This will show us what admin users exist and why authentication is failing"