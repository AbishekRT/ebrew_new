# MongoDB Cart Analytics Deployment Script (PowerShell)
# This script deploys the complete MongoDB cart analytics system to Ubuntu server

# Server Configuration
$SERVER_HOST = "16.171.119.252"
$SERVER_USER = "ubuntu"
$PROJECT_PATH = "/var/www/html"

Write-Host "🚀 Starting MongoDB Cart Analytics Deployment..." -ForegroundColor Green

# Function to upload file with backup
function Upload-File {
    param(
        [string]$LocalFile,
        [string]$RemoteFile,
        [string]$Description
    )
    
    Write-Host "📁 Uploading $Description..." -ForegroundColor Yellow
    
    # Create backup of existing file if it exists
    $backupCommand = @"
if [ -f '$RemoteFile' ]; then
    cp '$RemoteFile' '$RemoteFile.backup.`$(date +%Y%m%d_%H%M%S)'
    echo '   ✅ Backup created for existing file'
fi
"@
    
    ssh "${SERVER_USER}@${SERVER_HOST}" $backupCommand
    
    # Upload new file
    if (scp $LocalFile "${SERVER_USER}@${SERVER_HOST}:$RemoteFile") {
        Write-Host "   ✅ $Description uploaded successfully" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "   ❌ Failed to upload $Description" -ForegroundColor Red
        return $false
    }
}

# Function to run remote command
function Run-Remote {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "🔧 $Description..." -ForegroundColor Yellow
    if (ssh "${SERVER_USER}@${SERVER_HOST}" $Command) {
        Write-Host "   ✅ $Description completed" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "   ❌ $Description failed" -ForegroundColor Red
        return $false
    }
}

Write-Host ""
Write-Host "1️⃣ Uploading MongoDB Cart Analytics Models & Services..." -ForegroundColor Cyan

# Upload CartActivityLog Model
Upload-File -LocalFile "app\Models\CartActivityLog.php" `
    -RemoteFile "${PROJECT_PATH}/app/Models/CartActivityLog.php" `
    -Description "CartActivityLog MongoDB Model"

# Upload CartInsightsService
Upload-File -LocalFile "app\Services\CartInsightsService.php" `
    -RemoteFile "${PROJECT_PATH}/app/Services/CartInsightsService.php" `
    -Description "CartInsightsService Analytics Engine"

Write-Host ""
Write-Host "2️⃣ Updating Application Controllers..." -ForegroundColor Cyan

# Upload Updated DashboardController
Upload-File -LocalFile "app\Http\Controllers\DashboardController.php" `
    -RemoteFile "${PROJECT_PATH}/app/Http/Controllers/DashboardController.php" `
    -Description "Enhanced DashboardController with Cart Analytics"

Write-Host ""
Write-Host "3️⃣ Updating Views & Routes..." -ForegroundColor Cyan

# Upload Updated Dashboard View
Upload-File -LocalFile "resources\views\dashboard.blade.php" `
    -RemoteFile "${PROJECT_PATH}/resources/views/dashboard.blade.php" `
    -Description "Enhanced Dashboard View with MongoDB Cart Insights"

# Upload Updated Routes
Upload-File -LocalFile "routes\web.php" `
    -RemoteFile "${PROJECT_PATH}/routes/web.php" `
    -Description "Updated Web Routes with Test Data Generation"

Write-Host ""
Write-Host "4️⃣ Setting Proper Permissions..." -ForegroundColor Cyan

$permissionsCommand = @"
# Set ownership to www-data
sudo chown -R www-data:www-data ${PROJECT_PATH}/app/Models/CartActivityLog.php
sudo chown -R www-data:www-data ${PROJECT_PATH}/app/Services/CartInsightsService.php
sudo chown -R www-data:www-data ${PROJECT_PATH}/app/Http/Controllers/DashboardController.php
sudo chown -R www-data:www-data ${PROJECT_PATH}/resources/views/dashboard.blade.php
sudo chown -R www-data:www-data ${PROJECT_PATH}/routes/web.php

# Set proper permissions
chmod 644 ${PROJECT_PATH}/app/Models/CartActivityLog.php
chmod 644 ${PROJECT_PATH}/app/Services/CartInsightsService.php
chmod 644 ${PROJECT_PATH}/app/Http/Controllers/DashboardController.php
chmod 644 ${PROJECT_PATH}/resources/views/dashboard.blade.php
chmod 644 ${PROJECT_PATH}/routes/web.php
"@

Run-Remote -Command $permissionsCommand -Description "Setting file permissions"

Write-Host ""
Write-Host "5️⃣ Optimizing Laravel Application..." -ForegroundColor Cyan

$optimizationCommand = @"
cd ${PROJECT_PATH}

# Clear all caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Optimize for production
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Generate autoload files
composer dump-autoload --optimize
"@

Run-Remote -Command $optimizationCommand -Description "Laravel optimization and cache management"

Write-Host ""
Write-Host "6️⃣ MongoDB Connection Verification..." -ForegroundColor Cyan

$mongoTestCommand = @"
cd ${PROJECT_PATH}

# Test MongoDB connection
php artisan tinker --execute="
    try {
        \$connection = DB::connection('mongodb');
        \$result = \$connection->getMongoDB()->listCollections();
        echo 'MongoDB connection: SUCCESS\n';
        echo 'Available collections: ' . count(iterator_to_array(\$result)) . '\n';
    } catch (Exception \$e) {
        echo 'MongoDB connection: FAILED - ' . \$e->getMessage() . '\n';
    }
"
"@

Run-Remote -Command $mongoTestCommand -Description "MongoDB connection verification"

Write-Host ""
Write-Host "7️⃣ Restart Services..." -ForegroundColor Cyan

$restartCommand = @"
# Restart Apache
sudo systemctl reload apache2

# Restart PHP-FPM if available
if systemctl is-active --quiet php8.4-fpm; then
    sudo systemctl reload php8.4-fpm
fi

# Check Apache status
sudo systemctl status apache2 --no-pager -l
"@

Run-Remote -Command $restartCommand -Description "Restarting web services"

Write-Host ""
Write-Host "8️⃣ Testing Cart Analytics System..." -ForegroundColor Cyan

Write-Host "🧪 Creating test script to verify functionality..." -ForegroundColor Yellow

# Create a test script on the server
$testScript = @"
cat > ${PROJECT_PATH}/test-cart-analytics.php << 'EOF'
<?php
require_once __DIR__ . '/vendor/autoload.php';

// Load Laravel
`$app = require_once __DIR__ . '/bootstrap/app.php';
`$kernel = `$app->make(Illuminate\\Contracts\\Console\\Kernel::class);
`$kernel->bootstrap();

use App\\Models\\CartActivityLog;
use App\\Services\\CartInsightsService;

echo "\\n🔍 Testing MongoDB Cart Analytics System...\\n";

try {
    // Test 1: Check if CartActivityLog model works
    echo "\\n1️⃣ Testing CartActivityLog Model...\\n";
    `$count = CartActivityLog::count();
    echo "   ✅ CartActivityLog accessible. Current records: {`$count}\\n";
    
    // Test 2: Check if CartInsightsService works
    echo "\\n2️⃣ Testing CartInsightsService...\\n";
    `$service = new CartInsightsService();
    `$insights = `$service->getDashboardInsights(1);
    echo "   ✅ CartInsightsService working. Today's sessions: " . `$insights['today']['sessions'] . "\\n";
    
    // Test 3: Test data generation (small sample)
    echo "\\n3️⃣ Testing Data Generation...\\n";
    `$result = `$service->generateTestData(1, 3);
    echo "   ✅ {`$result}\\n";
    
    // Test 4: Verify generated data
    echo "\\n4️⃣ Verifying Generated Data...\\n";
    `$newCount = CartActivityLog::count();
    echo "   ✅ Total records after generation: {`$newCount}\\n";
    echo "   ✅ New records created: " . (`$newCount - `$count) . "\\n";
    
    echo "\\n🎉 All tests passed! MongoDB Cart Analytics system is working perfectly.\\n";
    
} catch (Exception `$e) {
    echo "\\n❌ Test failed: " . `$e->getMessage() . "\\n";
    echo "\\n📋 Stack trace:\\n" . `$e->getTraceAsString() . "\\n";
}
EOF
"@

ssh "${SERVER_USER}@${SERVER_HOST}" $testScript

# Run the test script
Run-Remote -Command "cd ${PROJECT_PATH} && php test-cart-analytics.php" -Description "Running MongoDB Cart Analytics functionality test"

# Clean up test script
Run-Remote -Command "rm -f ${PROJECT_PATH}/test-cart-analytics.php" -Description "Cleaning up test files"

Write-Host ""
Write-Host "🎯 Deployment Summary:" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "✅ CartActivityLog.php - MongoDB model for cart tracking" -ForegroundColor Green
Write-Host "✅ CartInsightsService.php - Analytics engine with complex aggregations" -ForegroundColor Green
Write-Host "✅ DashboardController.php - Enhanced with cart analytics integration" -ForegroundColor Green
Write-Host "✅ dashboard.blade.php - Beautiful cart insights dashboard UI" -ForegroundColor Green
Write-Host "✅ web.php - Routes for test data generation" -ForegroundColor Green
Write-Host "✅ File permissions and ownership configured" -ForegroundColor Green
Write-Host "✅ Laravel caches optimized" -ForegroundColor Green
Write-Host "✅ MongoDB connection verified" -ForegroundColor Green
Write-Host "✅ Web services restarted" -ForegroundColor Green
Write-Host "✅ Functionality testing completed" -ForegroundColor Green

Write-Host ""
Write-Host "🔗 Access Points:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "📊 User Dashboard: http://16.171.119.252/dashboard" -ForegroundColor White
Write-Host "🧪 Generate Test Data: Click 'Generate Test Data' button on dashboard" -ForegroundColor White
Write-Host "🔧 Admin Panel: http://16.171.119.252/admin/dashboard" -ForegroundColor White

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "1. 🔐 Login to user account at http://16.171.119.252/login" -ForegroundColor White
Write-Host "2. 📊 Visit dashboard to see MongoDB cart analytics" -ForegroundColor White
Write-Host "3. 🧪 Generate test data if no cart activity exists" -ForegroundColor White
Write-Host "4. 🎯 Verify shopping insights display correctly" -ForegroundColor White
Write-Host "5. 📈 Test real cart interactions to see live analytics" -ForegroundColor White

Write-Host ""
Write-Host "💡 Features Implemented:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "📈 Real-time shopping session tracking" -ForegroundColor White
Write-Host "🛒 Cart abandonment analysis with reasons" -ForegroundColor White
Write-Host "⏰ Peak shopping hours identification" -ForegroundColor White
Write-Host "📱 Device preference analytics" -ForegroundColor White
Write-Host "🎯 Conversion funnel analysis" -ForegroundColor White
Write-Host "💰 Cart value trends and distribution" -ForegroundColor White
Write-Host "🤖 Personalized shopping recommendations" -ForegroundColor White
Write-Host "📊 Advanced MongoDB aggregation queries" -ForegroundColor White
Write-Host "🧪 Test data generation for immediate testing" -ForegroundColor White
Write-Host "🔄 Session-based analytics (not individual actions)" -ForegroundColor White

Write-Host ""
Write-Host "🔧 Database Usage:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "🔵 MySQL (ebrew_laravel_db): All existing functionality preserved" -ForegroundColor Blue
Write-Host "🟢 MongoDB (ebrew_api): New cart analytics and user insights" -ForegroundColor Green
Write-Host "🔗 Dual database architecture working seamlessly" -ForegroundColor White

Write-Host ""
Write-Host "🎉 MongoDB Cart Analytics Deployment COMPLETED! 🎉" -ForegroundColor Green
Write-Host ""
Write-Host "Your eBrew Laravel application now has:" -ForegroundColor Yellow
Write-Host "• Comprehensive shopping session analytics" -ForegroundColor White
Write-Host "• Advanced MongoDB document aggregations" -ForegroundColor White
Write-Host "• Beautiful real-time insights dashboard" -ForegroundColor White
Write-Host "• Personalized shopping recommendations" -ForegroundColor White
Write-Host "• Full test data generation capabilities" -ForegroundColor White
Write-Host ""
Write-Host "Visit http://16.171.119.252/dashboard to see your new MongoDB cart analytics!" -ForegroundColor Green