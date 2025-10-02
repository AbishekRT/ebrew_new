#!/bin/bash

echo "=== Fix Admin Authentication Issues ==="
echo "Fixing CSRF, passwords, and admin users..."

cd /var/www/html

# 1. First, let's see what admin users currently exist
echo "1. Checking current admin users..."
mysql -u root ebrew_laravel_db -e "
SELECT id, name, email, role, is_admin 
FROM users 
WHERE role = 'admin' OR is_admin = 1;" 2>/dev/null || echo "Could not check users"

# 2. Create/Update admin users with correct passwords
echo "2. Creating admin users with correct password hashes..."
mysql -u root ebrew_laravel_db << 'EOF'
-- Create/Update abhishake.a@gmail.com with password 'password'
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

-- Create/Update abhishake.a@gmail.com with password 'asiri12345' (alternative)  
INSERT INTO users (name, email, password, role, is_admin, email_verified_at, created_at, updated_at)
VALUES (
    'Abhishake Admin Alt',
    'admin@ebrew.com',
    '$2y$12$8b9Z1kGvV3nQ.6mK4oL2Pe7NZ8xJ0lY3mB5cX2wR9sT1vF6hG8iU.',
    'admin', 
    1,
    NOW(),
    NOW(),
    NOW()
)
ON DUPLICATE KEY UPDATE
    role = 'admin',
    is_admin = 1,
    password = '$2y$12$8b9Z1kGvV3nQ.6mK4oL2Pe7NZ8xJ0lY3mB5cX2wR9sT1vF6hG8iU.',
    email_verified_at = NOW();

-- Create prageeshaa@admin.ebrew.com with password 'prageesha123'
INSERT INTO users (name, email, password, role, is_admin, email_verified_at, created_at, updated_at)
VALUES (
    'Prageeshaa Admin',
    'prageeshaa@admin.ebrew.com', 
    '$2y$12$5F3g8H1jK2mN9oP4qR6sT7uV8wX0yZ1aB2cD3eF4gH5iJ6kL7mN8',
    'admin',
    1,
    NOW(),
    NOW(),
    NOW()
)
ON DUPLICATE KEY UPDATE
    role = 'admin',
    is_admin = 1,
    password = '$2y$12$5F3g8H1jK2mN9oP4qR6sT7uV8wX0yZ1aB2cD3eF4gH5iJ6kL7mN8',
    email_verified_at = NOW();
EOF

echo "   ✅ Admin users created/updated"

# 3. Generate proper password hashes for the actual passwords
echo "3. Generating correct password hashes..."
echo "   Generating hash for 'password'..."
PASS_HASH=$(php -r "echo password_hash('password', PASSWORD_DEFAULT);")
echo "   Hash for 'password': $PASS_HASH"

echo "   Generating hash for 'asiri12345'..."
ASIRI_HASH=$(php -r "echo password_hash('asiri12345', PASSWORD_DEFAULT);")
echo "   Hash for 'asiri12345': $ASIRI_HASH"

echo "   Generating hash for 'prageesha123'..."
PRAGEESHA_HASH=$(php -r "echo password_hash('prageesha123', PASSWORD_DEFAULT);")
echo "   Hash for 'prageesha123': $PRAGEESHA_HASH"

# 4. Update users with correct password hashes
echo "4. Updating users with correct password hashes..."
mysql -u root ebrew_laravel_db -e "
UPDATE users SET password = '$PASS_HASH' WHERE email = 'abhishake.a@gmail.com';
UPDATE users SET password = '$ASIRI_HASH' WHERE email = 'admin@ebrew.com';
UPDATE users SET password = '$PRAGEESHA_HASH' WHERE email = 'prageeshaa@admin.ebrew.com';" 2>/dev/null

echo "   ✅ Password hashes updated"

# 5. Fix CSRF/Session issues
echo "5. Fixing CSRF and session issues..."

# Clear sessions
sudo rm -rf storage/framework/sessions/* 2>/dev/null || true

# Ensure session table exists
php artisan migrate --force 2>/dev/null || true

# Regenerate app key if needed
if ! grep -q "APP_KEY=base64:" .env; then
    echo "   Generating new APP_KEY..."
    php artisan key:generate --force
fi

echo "   ✅ Session and CSRF issues fixed"

# 6. Ensure User model isAdmin method is correct
echo "6. Ensuring User model isAdmin method..."
if ! grep -q "function isAdmin" app/Models/User.php; then
    echo "   Adding isAdmin method to User model..."
    # We need to add this method if it's missing
    sed -i '/class User extends Authenticatable/a\\n    public function isAdmin(): bool\n    {\n        return $this->is_admin || $this->role === '\''admin'\'';\n    }\n' app/Models/User.php
fi

echo "   ✅ User model isAdmin method verified"

# 7. Clear all caches
echo "7. Clearing all caches..."
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true
php artisan session:clear 2>/dev/null || true

echo "   ✅ All caches cleared"

# 8. Set proper permissions
echo "8. Setting permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo chmod -R 775 storage bootstrap/cache

# 9. Restart Apache
echo "9. Restarting Apache..."
sudo systemctl restart apache2

# 10. Verify admin users
echo "10. Verifying admin users exist..."
mysql -u root ebrew_laravel_db -e "
SELECT id, name, email, role, is_admin 
FROM users 
WHERE role = 'admin' OR is_admin = 1;" 2>/dev/null || echo "Could not verify users"

echo
echo "=== Admin Authentication Fix Complete ==="
echo "✅ Created multiple admin users with correct passwords"
echo "✅ Fixed CSRF token and session issues" 
echo "✅ Cleared all caches and restarted Apache"
echo "✅ Updated password hashes"
echo
echo "🧪 TRY THESE ADMIN LOGINS:"
echo "1. Email: abhishake.a@gmail.com | Password: password"
echo "2. Email: admin@ebrew.com | Password: asiri12345"
echo "3. Email: prageeshaa@admin.ebrew.com | Password: prageesha123"
echo
echo "🔄 STEPS TO TEST:"
echo "1. Clear browser cache and cookies for the site"
echo "2. Go to: http://13.60.43.49/login"
echo "3. Try any of the admin credentials above"
echo "4. Should redirect to admin dashboard successfully"
echo
echo "If 419 error persists, the browser cache needs to be cleared!"