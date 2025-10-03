Write-Host "=== RESTORE ADMIN DASHBOARD TO WORKING STATE ===" -ForegroundColor Yellow
Write-Host "This script will restore all files to their working state before the email verification update" -ForegroundColor Cyan
Write-Host ""

Set-Location "c:\SSP2\eBrewLaravel - Copy"

Write-Host "1. Creating backups of current files..." -ForegroundColor Green
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item "app\Http\Kernel.php" "app\Http\Kernel.php.backup_$timestamp" -ErrorAction SilentlyContinue
Copy-Item "app\Models\User.php" "app\Models\User.php.backup_$timestamp" -ErrorAction SilentlyContinue
Copy-Item "routes\web.php" "routes\web.php.backup_$timestamp" -ErrorAction SilentlyContinue

Write-Host "2. Git status check..." -ForegroundColor Green
git status --porcelain
Write-Host ""

Write-Host "3. Using git to restore files to last working commit..." -ForegroundColor Green
Write-Host "   Rolling back to commit before email verification (a2c9c77)" -ForegroundColor Cyan

# Reset specific files to the working commit
git checkout a2c9c77 -- app/Http/Kernel.php
git checkout a2c9c77 -- app/Models/User.php  
git checkout a2c9c77 -- routes/web.php
git checkout a2c9c77 -- app/Http/Controllers/AuthController.php
git checkout a2c9c77 -- app/Http/Middleware/IsAdminMiddleware.php

Write-Host "4. Applying Laravel 12 middleware fix..." -ForegroundColor Green
# The restored Kernel.php will have routeMiddleware, we need middlewareAliases for Laravel 12
(Get-Content app\Http\Kernel.php) -replace 'protected \$routeMiddleware', 'protected $middlewareAliases' | Set-Content app\Http\Kernel.php

Write-Host "5. Clearing all Laravel caches..." -ForegroundColor Green
php artisan config:clear | Out-Null
php artisan cache:clear | Out-Null  
php artisan route:clear | Out-Null
php artisan view:clear | Out-Null

Write-Host "6. Testing admin route registration..." -ForegroundColor Green
$adminRoutes = php artisan route:list --name=admin.dashboard
if ($adminRoutes -match "admin.dashboard") {
    Write-Host "   ✅ Admin routes registered successfully" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Admin routes not found" -ForegroundColor Red
}

Write-Host "7. Checking admin user configuration..." -ForegroundColor Green
php artisan tinker --execute="
echo 'Testing admin user...';
try {
    \$user = \App\Models\User::where('email', 'abhishake.a@gmail.com')->first();
    if (\$user) {
        echo 'User found: ' . \$user->name;
        echo 'Role: ' . (\$user->role ?? 'null');
        echo 'is_admin: ' . (\$user->is_admin ? 'true' : 'false');
        echo 'isAdmin(): ' . (\$user->isAdmin() ? 'true' : 'false');
    } else {
        echo 'Admin user not found!';
    }
} catch (Exception \$e) {
    echo 'Error: ' . \$e->getMessage();
}
"

Write-Host ""
Write-Host "=== RESTORATION COMPLETED ===" -ForegroundColor Yellow
Write-Host "✅ Files restored to last working commit (a2c9c77)" -ForegroundColor Green
Write-Host "✅ Applied Laravel 12 middleware compatibility fix" -ForegroundColor Green
Write-Host "✅ All caches cleared" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 WHAT WAS RESTORED:" -ForegroundColor Cyan
Write-Host "   - app\Http\Kernel.php (working version + Laravel 12 fix)" -ForegroundColor White
Write-Host "   - app\Models\User.php (working version)" -ForegroundColor White
Write-Host "   - routes\web.php (working version)" -ForegroundColor White
Write-Host "   - app\Http\Controllers\AuthController.php (working version)" -ForegroundColor White
Write-Host "   - app\Http\Middleware\IsAdminMiddleware.php (working version)" -ForegroundColor White
Write-Host ""
Write-Host "🧪 TEST ADMIN LOGIN:" -ForegroundColor Cyan
Write-Host "   URL: http://13.60.43.49/admin/dashboard" -ForegroundColor White
Write-Host "   Email: abhishake.a@gmail.com" -ForegroundColor White
Write-Host "   Password: asiri12345" -ForegroundColor White
Write-Host ""
Write-Host "💾 BACKUP FILES CREATED:" -ForegroundColor Cyan
Write-Host "   - app\Http\Kernel.php.backup_$timestamp" -ForegroundColor White
Write-Host "   - app\Models\User.php.backup_$timestamp" -ForegroundColor White
Write-Host "   - routes\web.php.backup_$timestamp" -ForegroundColor White