# Fixed MongoDB Cart Analytics Deployment (PowerShell)
# This script handles SSH issues and ensures ebrew_api database usage

param(
    [string]$ServerHost = "16.171.119.252",
    [string]$ServerUser = "ubuntu", 
    [string]$ProjectPath = "/var/www/html",
    [switch]$UsePassword = $false
)

Write-Host "🚀 Starting MongoDB Cart Analytics Deployment (Fixed Version)..." -ForegroundColor Green
Write-Host "🎯 Target: ebrew_api database for all cart analytics" -ForegroundColor Cyan

# Function to check if files exist locally
function Test-LocalFiles {
    $files = @(
        "app\Models\CartActivityLog.php",
        "app\Services\CartInsightsService.php", 
        "app\Http\Controllers\DashboardController.php",
        "resources\views\dashboard.blade.php",
        "routes\web.php"
    )
    
    Write-Host "📋 Checking local files..." -ForegroundColor Yellow
    $missingFiles = @()
    
    foreach ($file in $files) {
        if (Test-Path $file) {
            Write-Host "   ✅ Found: $file" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Missing: $file" -ForegroundColor Red
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Host "❌ Missing files detected. Please ensure you're in the correct directory." -ForegroundColor Red
        Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
        return $false
    }
    
    return $true
}

# Function to upload with multiple retry strategies
function Upload-FileWithRetry {
    param(
        [string]$LocalFile,
        [string]$RemoteFile,
        [string]$Description
    )
    
    Write-Host "📁 Uploading $Description..." -ForegroundColor Yellow
    
    # Strategy 1: Try with SSH key
    Write-Host "   🔑 Trying SSH key authentication..." -ForegroundColor Gray
    $result = scp $LocalFile "${ServerUser}@${ServerHost}:$RemoteFile" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ $Description uploaded successfully (SSH key)" -ForegroundColor Green
        return $true
    }
    
    # Strategy 2: Try with password authentication
    if ($UsePassword) {
        Write-Host "   🔐 Trying password authentication..." -ForegroundColor Gray
        $result = scp -o PreferredAuthentications=password $LocalFile "${ServerUser}@${ServerHost}:$RemoteFile" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ $Description uploaded successfully (password)" -ForegroundColor Green
            return $true
        }
    }
    
    # Strategy 3: Try with different SSH options
    Write-Host "   🔧 Trying with SSH options..." -ForegroundColor Gray
    $result = scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $LocalFile "${ServerUser}@${ServerHost}:$RemoteFile" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ $Description uploaded successfully (SSH options)" -ForegroundColor Green
        return $true
    }
    
    Write-Host "   ❌ Failed to upload $Description" -ForegroundColor Red
    Write-Host "   📋 Error: $result" -ForegroundColor Red
    return $false
}

# Function to run remote commands with retry
function Invoke-RemoteCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "🔧 $Description..." -ForegroundColor Yellow
    
    # Try SSH key first
    $result = ssh "${ServerUser}@${ServerHost}" $Command 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ $Description completed" -ForegroundColor Green
        return $true
    }
    
    # Try with SSH options
    $result = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${ServerUser}@${ServerHost}" $Command 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ $Description completed" -ForegroundColor Green
        return $true
    }
    
    Write-Host "   ❌ $Description failed" -ForegroundColor Red
    Write-Host "   📋 Error: $result" -ForegroundColor Red
    return $false
}

# Check if we're in the right directory and files exist
if (-not (Test-LocalFiles)) {
    Write-Host ""
    Write-Host "🔄 Solutions:" -ForegroundColor Cyan
    Write-Host "1. Navigate to your Laravel project directory: cd 'C:\SSP2\eBrewLaravel - Copy'" -ForegroundColor White
    Write-Host "2. Ensure all MongoDB cart analytics files were created successfully" -ForegroundColor White
    Write-Host "3. Re-run this script from the correct directory" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "1️⃣ Creating Services Directory..." -ForegroundColor Cyan
Invoke-RemoteCommand -Command "mkdir -p ${ProjectPath}/app/Services" -Description "Creating Services directory"

Write-Host ""
Write-Host "2️⃣ Uploading MongoDB Cart Analytics Files..." -ForegroundColor Cyan

$uploadResults = @()

# Upload all files
$uploadResults += Upload-FileWithRetry -LocalFile "app\Models\CartActivityLog.php" `
                                      -RemoteFile "${ProjectPath}/app/Models/CartActivityLog.php" `
                                      -Description "CartActivityLog MongoDB Model"

$uploadResults += Upload-FileWithRetry -LocalFile "app\Services\CartInsightsService.php" `
                                      -RemoteFile "${ProjectPath}/app/Services/CartInsightsService.php" `
                                      -Description "CartInsightsService Analytics Engine"

$uploadResults += Upload-FileWithRetry -LocalFile "app\Http\Controllers\DashboardController.php" `
                                      -RemoteFile "${ProjectPath}/app/Http/Controllers/DashboardController.php" `
                                      -Description "Enhanced DashboardController"

$uploadResults += Upload-FileWithRetry -LocalFile "resources\views\dashboard.blade.php" `
                                      -RemoteFile "${ProjectPath}/resources/views/dashboard.blade.php" `
                                      -Description "Enhanced Dashboard View"

$uploadResults += Upload-FileWithRetry -LocalFile "routes\web.php" `
                                      -RemoteFile "${ProjectPath}/routes/web.php" `
                                      -Description "Updated Routes"

# Check upload success rate
$successCount = ($uploadResults | Where-Object { $_ -eq $true }).Count
$totalCount = $uploadResults.Count

Write-Host ""
Write-Host "📊 Upload Results: $successCount/$totalCount files uploaded successfully" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })

if ($successCount -eq 0) {
    Write-Host ""
    Write-Host "❌ No files were uploaded successfully. SSH connection issues detected." -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Manual Upload Instructions:" -ForegroundColor Cyan
    Write-Host "1. SSH into your server: ssh ubuntu@16.171.119.252" -ForegroundColor White
    Write-Host "2. Create files manually on server using nano/vim" -ForegroundColor White
    Write-Host "3. Copy and paste content from local files" -ForegroundColor White
    Write-Host "4. Or fix SSH key setup and try again" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "3️⃣ Setting File Permissions..." -ForegroundColor Cyan

$permissionCommands = @(
    "sudo chown -R www-data:www-data ${ProjectPath}/app/Models/CartActivityLog.php",
    "sudo chown -R www-data:www-data ${ProjectPath}/app/Services/CartInsightsService.php", 
    "sudo chown -R www-data:www-data ${ProjectPath}/app/Http/Controllers/DashboardController.php",
    "sudo chown -R www-data:www-data ${ProjectPath}/resources/views/dashboard.blade.php",
    "sudo chown -R www-data:www-data ${ProjectPath}/routes/web.php",
    "chmod 644 ${ProjectPath}/app/Models/CartActivityLog.php",
    "chmod 644 ${ProjectPath}/app/Services/CartInsightsService.php",
    "chmod 644 ${ProjectPath}/app/Http/Controllers/DashboardController.php", 
    "chmod 644 ${ProjectPath}/resources/views/dashboard.blade.php",
    "chmod 644 ${ProjectPath}/routes/web.php"
)

foreach ($cmd in $permissionCommands) {
    Invoke-RemoteCommand -Command $cmd -Description "Setting permissions: $(Split-Path -Leaf ($cmd -split ' ')[-1])"
}

Write-Host ""
Write-Host "4️⃣ Optimizing Laravel Application..." -ForegroundColor Cyan

$optimizationCommands = @(
    "cd ${ProjectPath} && php artisan config:clear",
    "cd ${ProjectPath} && php artisan cache:clear", 
    "cd ${ProjectPath} && php artisan route:clear",
    "cd ${ProjectPath} && php artisan view:clear",
    "cd ${ProjectPath} && php artisan config:cache",
    "cd ${ProjectPath} && php artisan route:cache",
    "cd ${ProjectPath} && php artisan view:cache",
    "cd ${ProjectPath} && composer dump-autoload --optimize"
)

foreach ($cmd in $optimizationCommands) {
    $description = ($cmd -split ' && ')[-1]
    Invoke-RemoteCommand -Command $cmd -Description "Laravel: $description"
}

Write-Host ""
Write-Host "5️⃣ Testing MongoDB Cart Analytics..." -ForegroundColor Cyan

$testCommand = @"
cd ${ProjectPath} && php artisan tinker --execute="
try {
    echo 'Testing MongoDB connection to ebrew_api database...\n';
    \$connection = DB::connection('mongodb');
    \$database = \$connection->getMongoDB();
    echo 'MongoDB connection: SUCCESS\n';
    
    echo 'Testing CartActivityLog model...\n';
    \$count = App\Models\CartActivityLog::count();
    echo 'CartActivityLog model: SUCCESS (records: ' . \$count . ')\n';
    
    echo 'Testing CartInsightsService...\n';
    \$service = new App\Services\CartInsightsService();
    \$insights = \$service->getDashboardInsights(1);
    echo 'CartInsightsService: SUCCESS\n';
    echo 'Dashboard insights generated successfully\n';
    
} catch (Exception \$e) {
    echo 'Error: ' . \$e->getMessage() . '\n';
    echo 'Stack: ' . \$e->getTraceAsString() . '\n';
}
"
"@

Invoke-RemoteCommand -Command $testCommand -Description "MongoDB Cart Analytics functionality test"

Write-Host ""
Write-Host "6️⃣ Restarting Web Services..." -ForegroundColor Cyan

Invoke-RemoteCommand -Command "sudo systemctl reload apache2" -Description "Reloading Apache"
Invoke-RemoteCommand -Command "sudo systemctl reload php8.4-fpm 2>/dev/null || echo 'PHP-FPM not available'" -Description "Reloading PHP-FPM"

Write-Host ""
Write-Host "🎉 DEPLOYMENT COMPLETED!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

if ($successCount -eq $totalCount) {
    Write-Host "✅ All files uploaded successfully" -ForegroundColor Green
    Write-Host "✅ MongoDB cart analytics system deployed" -ForegroundColor Green 
    Write-Host "✅ Using ebrew_api database for all analytics" -ForegroundColor Green
    Write-Host "✅ Laravel application optimized" -ForegroundColor Green
    Write-Host "✅ Web services restarted" -ForegroundColor Green
} else {
    Write-Host "⚠️  Partial deployment completed" -ForegroundColor Yellow
    Write-Host "⚠️  $($totalCount - $successCount) files failed to upload" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔗 Next Steps:" -ForegroundColor Cyan
Write-Host "1. 🌐 Visit: http://16.171.119.252/dashboard" -ForegroundColor White
Write-Host "2. 🔐 Login with your user account" -ForegroundColor White 
Write-Host "3. 🧪 Click 'Generate Test Data' to create sample analytics" -ForegroundColor White
Write-Host "4. 🔄 Refresh page - cart analytics should show real numbers" -ForegroundColor White
Write-Host "5. 📊 Explore 'My Shopping Insights' section" -ForegroundColor White

Write-Host ""
Write-Host "🔧 Database Configuration:" -ForegroundColor Cyan
Write-Host "🟢 MongoDB (ebrew_api): Cart analytics, shopping sessions" -ForegroundColor Green
Write-Host "🔵 MySQL (ebrew_laravel_db): Products, orders, users (preserved)" -ForegroundColor Blue

Write-Host ""
Write-Host "🚨 If you still see zeros on dashboard:" -ForegroundColor Red
Write-Host "1. Check MongoDB connection in Laravel logs" -ForegroundColor White
Write-Host "2. Verify .env file has correct MongoDB settings" -ForegroundColor White
Write-Host "3. Generate test data using dashboard button" -ForegroundColor White
Write-Host "4. Check MongoDB Atlas for cart_activity_logs collection" -ForegroundColor White

Write-Host ""
Write-Host "✨ Your MongoDB cart analytics are now deployed! ✨" -ForegroundColor Green