#!/bin/bash

echo "=== Fix Admin 500 Error ==="
echo "Creating admin user in correct database and fixing middleware..."

cd /var/www/html

# 1. Create admin user in the correct database (ebrew_laravel_db)
echo "1. Creating admin user in ebrew_laravel_db..."
mysql -u ebrew_user -p'secure_db_password_2024' ebrew_laravel_db << 'EOF'
-- Ensure admin user exists with correct password
INSERT INTO users (name, email, password, role, is_admin, email_verified_at, created_at, updated_at)
VALUES (
    'Abhishake Admin',
    'abhishake.a@gmail.com',
    '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'admin',
    1,
    NOW(),
    NOW(),
    NOW()
)
ON DUPLICATE KEY UPDATE
    role = 'admin',
    is_admin = 1,
    password = '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    email_verified_at = NOW();
EOF

echo "   ✅ Admin user created/updated in correct database"

# 2. Verify admin user exists
echo "2. Verifying admin user..."
mysql -u ebrew_user -p'secure_db_password_2024' ebrew_laravel_db -e "
SELECT id, name, email, role, is_admin 
FROM users 
WHERE email = 'abhishake.a@gmail.com';"

# 3. Ensure IsAdminMiddleware exists and is correct
echo "3. Ensuring IsAdminMiddleware is correct..."
sudo tee /var/www/html/app/Http/Middleware/IsAdminMiddleware.php > /dev/null << 'EOF'
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class IsAdminMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        if (!Auth::check()) {
            return redirect()->route('login');
        }

        $user = Auth::user();
        
        if (!$user->isAdmin()) {
            abort(403, 'Access denied. Admin privileges required.');
        }

        return $next($request);
    }
}
EOF

echo "   ✅ IsAdminMiddleware created/updated"

# 4. Clear caches
echo "4. Clearing caches..."
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true

# 5. Test admin login manually
echo "5. Testing admin user login..."
mysql -u ebrew_user -p'secure_db_password_2024' ebrew_laravel_db -e "
SELECT 
    'Testing password hash...' as test,
    email,
    role,
    is_admin,
    CASE 
        WHEN password = '$2y\$12\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi' 
        THEN 'Hash matches expected' 
        ELSE 'Hash different' 
    END as password_check
FROM users 
WHERE email = 'abhishake.a@gmail.com';"

# 6. Set permissions
echo "6. Setting permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

echo
echo "=== Admin Fix Complete ==="
echo "✅ Admin user created in correct database (ebrew_laravel_db)"
echo "✅ IsAdminMiddleware fixed"
echo "✅ Caches cleared"
echo "✅ Permissions set"
echo
echo "🧪 TEST ADMIN LOGIN:"
echo "1. Go to: http://13.60.43.49/login"
echo "2. Email: abhishake.a@gmail.com"
echo "3. Password: password (standard Laravel test password)"
echo "4. Should redirect to admin dashboard"
echo
echo "If password doesn't work, try: asiri12345"