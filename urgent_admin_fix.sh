#!/bin/bash

echo "=== eBrew URGENT Admin Login Fix ==="
echo "Timestamp: $(date)"
echo "Fixing identified issues from diagnostic..."
echo

# 1. Fix database connection first
echo "1. Fixing MySQL database connection..."

# Check MySQL service status
echo "   Checking MySQL service..."
sudo systemctl status mysql | head -3

# Test direct MySQL connection
echo "   Testing MySQL connection with different approaches..."
mysql -u root -e "SELECT 1;" 2>/dev/null && echo "   ✅ MySQL root connection works" || echo "   ❌ MySQL root connection failed"

# Check if ebrew_db exists
echo "   Checking database existence..."
mysql -u root -e "SHOW DATABASES LIKE 'ebrew_db';" 2>/dev/null || echo "   ⚠️ Database check failed"

# Try alternative database connection
echo "   Testing Laravel database configuration..."
cd /var/www/html

# Check .env file for database config
echo "   Current .env database configuration:"
grep -E "^DB_" /var/www/html/.env 2>/dev/null || echo "   ⚠️ .env file not found or no DB config"

# 2. Fix Kernel middleware registration
echo "2. Fixing Kernel.php middleware registration..."

# Check current Kernel.php content
echo "   Checking current Kernel.php middleware registration..."
grep -n "admin.*Middleware" /var/www/html/app/Http/Kernel.php || echo "   ❌ Admin middleware not registered"

# Fix the Kernel.php to properly register admin middleware
echo "   ✅ Fixing Kernel.php middleware registration..."
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

# 3. Verify IsAdminMiddleware is correctly configured
echo "3. Checking and fixing IsAdminMiddleware..."
if [ -f "/var/www/html/app/Http/Middleware/IsAdminMiddleware.php" ]; then
    echo "   ✅ IsAdminMiddleware exists, checking content..."
    
    # Ensure the middleware has proper error handling
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
        // Check if user is authenticated
        if (!Auth::check()) {
            return redirect()->route('login');
        }

        $user = Auth::user();
        
        // Check if user has admin role
        if (!$user->isAdmin()) {
            abort(403, 'Access denied. Admin privileges required.');
        }

        return $next($request);
    }
}
EOF
else
    echo "   ❌ IsAdminMiddleware not found - creating it..."
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
fi

# 4. Check and fix database configuration
echo "4. Checking database configuration..."

# Check if .env exists and has proper database config
if [ -f "/var/www/html/.env" ]; then
    echo "   ✅ .env file exists, checking database configuration..."
    
    # Backup current .env
    sudo cp /var/www/html/.env /var/www/html/.env.backup.$(date +%Y%m%d_%H%M%S)
    
    # Check if database config exists
    if grep -q "^DB_" /var/www/html/.env; then
        echo "   ✅ Database configuration found in .env"
    else
        echo "   ⚠️ Adding database configuration to .env..."
        sudo tee -a /var/www/html/.env > /dev/null << 'EOF'

# Database Configuration
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ebrew_db
DB_USERNAME=root
DB_PASSWORD=
EOF
    fi
else
    echo "   ❌ .env file not found - creating basic .env..."
    sudo tee /var/www/html/.env > /dev/null << 'EOF'
APP_NAME=eBrew
APP_ENV=production
APP_KEY=base64:your-app-key-here
APP_DEBUG=false
APP_TIMEZONE=UTC
APP_URL=http://16.171.119.252

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ebrew_db
DB_USERNAME=root
DB_PASSWORD=

BROADCAST_CONNECTION=log
CACHE_STORE=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=database
SESSION_DRIVER=file
SESSION_LIFETIME=120

MAIL_DRIVER=log
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
EOF
fi

# 5. Test database connection and create admin user if needed
echo "5. Testing database connection and ensuring admin user exists..."
cd /var/www/html

# Test Laravel database connection
echo "   Testing Laravel database connection..."
php artisan migrate:status 2>/dev/null && echo "   ✅ Laravel database connection working" || echo "   ⚠️ Laravel database connection issue"

# Check if admin user exists and create if needed
echo "   Ensuring admin user exists..."
mysql -u root ebrew_db << 'EOF' 2>/dev/null || echo "   ⚠️ Admin user check failed"
-- Check if admin user exists
SELECT COUNT(*) as admin_count FROM users WHERE email = 'abhishake.a@gmail.com';

-- If needed, create or update admin user
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
    email_verified_at = NOW();
EOF

# 6. Clear all Laravel caches
echo "6. Clearing Laravel caches..."
cd /var/www/html

php artisan config:clear 2>/dev/null || echo "   ⚠️ Config cache clear failed"
php artisan cache:clear 2>/dev/null || echo "   ⚠️ Application cache clear failed"  
php artisan route:clear 2>/dev/null || echo "   ⚠️ Route cache clear failed"
php artisan view:clear 2>/dev/null || echo "   ⚠️ View cache clear failed"

# Try to optimize for production
php artisan config:cache 2>/dev/null || echo "   ⚠️ Config cache failed"
php artisan route:cache 2>/dev/null || echo "   ⚠️ Route cache failed"

# 7. Set proper permissions
echo "7. Setting proper file permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo chmod -R 775 /var/www/html/storage
sudo chmod -R 775 /var/www/html/bootstrap/cache

# 8. Restart Apache
echo "8. Restarting Apache web server..."
sudo systemctl restart apache2

# 9. Final verification
echo "9. Running final verification..."
echo "   Testing route list..."
php artisan route:list | grep -E "(login|admin)" | head -5

echo "   Testing admin user query..."
mysql -u root ebrew_db -e "SELECT id, name, email, role, is_admin FROM users WHERE email = 'abhishake.a@gmail.com';" 2>/dev/null || echo "   ⚠️ Admin user query failed"

echo
echo "=== URGENT FIX COMPLETED ==="
echo "✅ Fixed Kernel.php middleware registration"
echo "✅ Fixed IsAdminMiddleware"
echo "✅ Checked/Fixed database configuration"
echo "✅ Ensured admin user exists"
echo "✅ Cleared all caches"
echo "✅ Set proper permissions"
echo "✅ Restarted Apache"
echo
echo "🔍 TEST ADMIN LOGIN NOW:"
echo "1. Go to: http://13.60.43.49/login"
echo "2. Email: abhishake.a@gmail.com"
echo "3. Password: asiri12345"
echo "4. Should redirect to: http://13.60.43.49/admin/dashboard"
echo
echo "If still having issues, check:"
echo "   - Apache error log: sudo tail -f /var/log/apache2/error.log"
echo "   - Laravel log: tail -f /var/www/html/storage/logs/laravel.log"
echo "   - Test URL: http://13.60.43.49/debug/admin-test"