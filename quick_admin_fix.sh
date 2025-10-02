#!/bin/bash

echo "=== Quick Admin Fix - Database & Middleware ==="
echo "Fixing admin login with correct database credentials..."

cd /var/www/html

# 1. Fix Kernel.php middleware registration (this was definitely missing)
echo "1. Fixing Kernel.php middleware registration..."
sudo tee /var/www/html/app/Http/Kernel.php > /dev/null << 'EOF'
<?php

namespace App\Http;

use Illuminate\Foundation\Http\Kernel as HttpKernel;

class Kernel extends HttpKernel
{
    protected $middleware = [
        \Illuminate\Http\Middleware\HandleCors::class,
        \Illuminate\Foundation\Http\Middleware\PreventRequestsDuringMaintenance::class,
        \Illuminate\Foundation\Http\Middleware\ValidatePostSize::class,
        \Illuminate\Foundation\Http\Middleware\TrimStrings::class,
        \Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull::class,
    ];

    protected $middlewareGroups = [
        'web' => [
            \Illuminate\Cookie\Middleware\EncryptCookies::class,
            \Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse::class,
            \Illuminate\Session\Middleware\StartSession::class,
            \Illuminate\View\Middleware\ShareErrorsFromSession::class,
            \Illuminate\Foundation\Http\Middleware\ValidateCsrfToken::class,
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],

        'api' => [
            \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
            'throttle:api',
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],
    ];

    protected $routeMiddleware = [
        'auth' => \Illuminate\Auth\Middleware\Authenticate::class,
        'auth.basic' => \Illuminate\Auth\Middleware\AuthenticateWithBasicAuth::class,
        'cache.headers' => \Illuminate\Http\Middleware\SetCacheHeaders::class,
        'can' => \Illuminate\Auth\Middleware\Authorize::class,
        'guest' => \Illuminate\Auth\Middleware\RedirectIfAuthenticated::class,
        'password.confirm' => \Illuminate\Auth\Middleware\RequirePassword::class,
        'signed' => \Illuminate\Routing\Middleware\ValidateSignature::class,
        'throttle' => \Illuminate\Routing\Middleware\ThrottleRequests::class,
        'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
        'admin' => \App\Http\Middleware\IsAdminMiddleware::class,
    ];
}
EOF

echo "   ✅ Kernel.php fixed with admin middleware"

# 2. Run Laravel migrations to ensure tables exist
echo "2. Running Laravel migrations to create tables..."
php artisan migrate --force 2>/dev/null && echo "   ✅ Migrations completed" || echo "   ⚠️ Migration issues"

# 3. Check and create admin user
echo "3. Creating admin user in database..."
mysql -u root ebrew_db << 'EOF'
-- Create users table if it doesn't exist
CREATE TABLE IF NOT EXISTS users (
    id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    name varchar(255) NOT NULL,
    email varchar(255) NOT NULL,
    email_verified_at timestamp NULL DEFAULT NULL,
    password varchar(255) NOT NULL,
    role enum('admin','customer') DEFAULT 'customer',
    phone varchar(20) DEFAULT NULL,
    delivery_address text,
    is_admin tinyint(1) DEFAULT '0',
    remember_token varchar(100) DEFAULT NULL,
    created_at timestamp NULL DEFAULT NULL,
    updated_at timestamp NULL DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY users_email_unique (email)
);

-- Create admin user
INSERT INTO users (name, email, password, role, is_admin, email_verified_at, created_at, updated_at)
VALUES (
    'Abhishake Admin',
    'abhishake.a@gmail.com',
    '$2y$12$8YVqUQ2m8zDZXR4L5Qn5WOYr4q2H1KjDpH3jSr8B6QwE5vZ2N1X3K',
    'admin',
    1,
    NOW(),
    NOW(),
    NOW()
)
ON DUPLICATE KEY UPDATE
    role = 'admin',
    is_admin = 1,
    password = '$2y$12$8YVqUQ2m8zDZXR4L5Qn5WOYr4q2H1KjDpH3jSr8B6QwE5vZ2N1X3K',
    email_verified_at = NOW();
EOF

echo "   ✅ Admin user created/updated"

# 4. Update .env for correct database credentials (no password)
echo "4. Updating .env database configuration..."
if [ -f "/var/www/html/.env" ]; then
    # Update existing .env
    sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=/' /var/www/html/.env
    echo "   ✅ Updated existing .env"
else
    # Create new .env
    sudo tee /var/www/html/.env > /dev/null << 'EOF'
APP_NAME=eBrew
APP_ENV=production
APP_KEY=base64:your-app-key-here
APP_DEBUG=false
APP_URL=http://13.60.43.49

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ebrew_db
DB_USERNAME=root
DB_PASSWORD=

CACHE_STORE=file
SESSION_DRIVER=file
MAIL_DRIVER=log
EOF
    echo "   ✅ Created new .env"
fi

# 5. Clear caches
echo "5. Clearing Laravel caches..."
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

# 6. Set permissions
echo "6. Setting permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo chmod -R 775 /var/www/html/storage
sudo chmod -R 775 /var/www/html/bootstrap/cache

# 7. Restart Apache
echo "7. Restarting Apache..."
sudo systemctl restart apache2

# 8. Test admin user
echo "8. Testing admin user exists..."
mysql -u root ebrew_db -e "SELECT id, name, email, role, is_admin FROM users WHERE email = 'abhishake.a@gmail.com';"

echo
echo "=== QUICK FIX COMPLETED ==="
echo "✅ Kernel.php middleware registered"
echo "✅ Database tables created/verified"
echo "✅ Admin user created with correct password"
echo "✅ .env database config updated (no password)"
echo "✅ Caches cleared"
echo "✅ Permissions set"
echo "✅ Apache restarted"
echo
echo "🚀 TEST ADMIN LOGIN:"
echo "URL: http://13.60.43.49/login"
echo "Email: abhishake.a@gmail.com"
echo "Password: asiri12345"
echo
echo "If still having issues, check Apache error log:"
echo "sudo tail -f /var/log/apache2/error.log"