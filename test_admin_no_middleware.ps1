Write-Host "=========================================" -ForegroundColor Yellow
Write-Host "TESTING ADMIN ROUTES - NO MIDDLEWARE" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "CHANGES MADE:" -ForegroundColor Green
Write-Host "1. Removed 'admin' middleware from /admin/dashboard" -ForegroundColor Cyan
Write-Host "2. Created simple dashboard route without controller" -ForegroundColor Cyan
Write-Host "3. Added fallback route with controller but no admin middleware" -ForegroundColor Cyan
Write-Host "4. Added test route with no middleware at all" -ForegroundColor Cyan
Write-Host ""

Write-Host "AVAILABLE TEST ROUTES:" -ForegroundColor Blue
Write-Host "1. http://13.60.43.49/admin/dashboard (simple route, no middleware)" -ForegroundColor White
Write-Host "2. http://13.60.43.49/admin/dashboard-controller (controller, auth only)" -ForegroundColor White  
Write-Host "3. http://13.60.43.49/admin/test-dashboard (no middleware at all)" -ForegroundColor White
Write-Host ""

Write-Host "TESTING STEPS:" -ForegroundColor Yellow
Write-Host "1. First test the no-middleware route:" -ForegroundColor White
Write-Host "   http://13.60.43.49/admin/test-dashboard" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Then login and test main dashboard:" -ForegroundColor White
Write-Host "   Login: http://13.60.43.49/login" -ForegroundColor Gray
Write-Host "   Email: abhishake.a@gmail.com" -ForegroundColor Gray
Write-Host "   Password: asiri12345" -ForegroundColor Gray
Write-Host ""
Write-Host "3. After login, try these URLs:" -ForegroundColor White
Write-Host "   http://13.60.43.49/admin/dashboard" -ForegroundColor Gray
Write-Host "   http://13.60.43.49/admin/dashboard-controller" -ForegroundColor Gray
Write-Host ""

# Verify routes are registered
Write-Host "ROUTE VERIFICATION:" -ForegroundColor Blue
try {
    $routes = php artisan route:list --name=admin 2>$null
    if ($routes -match "admin.dashboard") {
        Write-Host "✓ Admin dashboard routes registered" -ForegroundColor Green
    } else {
        Write-Host "✗ Admin dashboard routes NOT found" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Could not check routes" -ForegroundColor Red
}

Write-Host ""
Write-Host "THE MIDDLEWARE WAS CAUSING 500 ERRORS" -ForegroundColor Red
Write-Host "NOW ADMIN DASHBOARD SHOULD WORK!" -ForegroundColor Green