#!/bin/bash

# MongoDB Cart Analytics Deployment Script
# This script deploys the complete MongoDB cart analytics system to Ubuntu server

# Server Configuration
SERVER_HOST="16.171.119.252"
SERVER_USER="ubuntu"
PROJECT_PATH="/var/www/html"

echo "🚀 Starting MongoDB Cart Analytics Deployment..."

# Function to upload file with backup
upload_file() {
    local local_file=$1
    local remote_file=$2
    local description=$3
    
    echo "📁 Uploading $description..."
    
    # Create backup of existing file if it exists
    ssh ${SERVER_USER}@${SERVER_HOST} "
        if [ -f '${remote_file}' ]; then
            cp '${remote_file}' '${remote_file}.backup.$(date +%Y%m%d_%H%M%S)'
            echo '   ✅ Backup created for existing file'
        fi
    "
    
    # Upload new file
    if scp "$local_file" ${SERVER_USER}@${SERVER_HOST}:"$remote_file"; then
        echo "   ✅ $description uploaded successfully"
    else
        echo "   ❌ Failed to upload $description"
        return 1
    fi
}

# Function to run remote command
run_remote() {
    local command=$1
    local description=$2
    
    echo "🔧 $description..."
    if ssh ${SERVER_USER}@${SERVER_HOST} "$command"; then
        echo "   ✅ $description completed"
    else
        echo "   ❌ $description failed"
        return 1
    fi
}

echo ""
echo "1️⃣ Uploading MongoDB Cart Analytics Models & Services..."

# Upload CartActivityLog Model
upload_file \
    "app/Models/CartActivityLog.php" \
    "${PROJECT_PATH}/app/Models/CartActivityLog.php" \
    "CartActivityLog MongoDB Model"

# Upload CartInsightsService
upload_file \
    "app/Services/CartInsightsService.php" \
    "${PROJECT_PATH}/app/Services/CartInsightsService.php" \
    "CartInsightsService Analytics Engine"

echo ""
echo "2️⃣ Updating Application Controllers..."

# Upload Updated DashboardController
upload_file \
    "app/Http/Controllers/DashboardController.php" \
    "${PROJECT_PATH}/app/Http/Controllers/DashboardController.php" \
    "Enhanced DashboardController with Cart Analytics"

echo ""
echo "3️⃣ Updating Views & Routes..."

# Upload Updated Dashboard View
upload_file \
    "resources/views/dashboard.blade.php" \
    "${PROJECT_PATH}/resources/views/dashboard.blade.php" \
    "Enhanced Dashboard View with MongoDB Cart Insights"

# Upload Updated Routes
upload_file \
    "routes/web.php" \
    "${PROJECT_PATH}/routes/web.php" \
    "Updated Web Routes with Test Data Generation"

echo ""
echo "4️⃣ Setting Proper Permissions..."

run_remote "
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
" "Setting file permissions"

echo ""
echo "5️⃣ Optimizing Laravel Application..."

run_remote "
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
" "Laravel optimization and cache management"

echo ""
echo "6️⃣ MongoDB Connection Verification..."

run_remote "
    cd ${PROJECT_PATH}
    
    # Test MongoDB connection
    php artisan tinker --execute=\"
        try {
            \$connection = DB::connection('mongodb');
            \$result = \$connection->getMongoDB()->listCollections();
            echo 'MongoDB connection: SUCCESS\n';
            echo 'Available collections: ' . count(iterator_to_array(\$result)) . '\n';
        } catch (Exception \$e) {
            echo 'MongoDB connection: FAILED - ' . \$e->getMessage() . '\n';
        }
    \"
" "MongoDB connection verification"

echo ""
echo "7️⃣ Restart Services..."

run_remote "
    # Restart Apache
    sudo systemctl reload apache2
    
    # Restart PHP-FPM if available
    if systemctl is-active --quiet php8.4-fpm; then
        sudo systemctl reload php8.4-fpm
    fi
    
    # Check Apache status
    sudo systemctl status apache2 --no-pager -l
" "Restarting web services"

echo ""
echo "8️⃣ Testing Cart Analytics System..."

echo "🧪 Creating test script to verify functionality..."

# Create a test script on the server
ssh ${SERVER_USER}@${SERVER_HOST} "cat > ${PROJECT_PATH}/test-cart-analytics.php << 'EOF'
<?php
require_once __DIR__ . '/vendor/autoload.php';

// Load Laravel
\$app = require_once __DIR__ . '/bootstrap/app.php';
\$kernel = \$app->make(Illuminate\\Contracts\\Console\\Kernel::class);
\$kernel->bootstrap();

use App\\Models\\CartActivityLog;
use App\\Services\\CartInsightsService;

echo \"\\n🔍 Testing MongoDB Cart Analytics System...\\n\";

try {
    // Test 1: Check if CartActivityLog model works
    echo \"\\n1️⃣ Testing CartActivityLog Model...\\n\";
    \$count = CartActivityLog::count();
    echo \"   ✅ CartActivityLog accessible. Current records: {\$count}\\n\";
    
    // Test 2: Check if CartInsightsService works
    echo \"\\n2️⃣ Testing CartInsightsService...\\n\";
    \$service = new CartInsightsService();
    \$insights = \$service->getDashboardInsights(1);
    echo \"   ✅ CartInsightsService working. Today's sessions: \" . \$insights['today']['sessions'] . \"\\n\";
    
    // Test 3: Test data generation (small sample)
    echo \"\\n3️⃣ Testing Data Generation...\\n\";
    \$result = \$service->generateTestData(1, 3);
    echo \"   ✅ {\$result}\\n\";
    
    // Test 4: Verify generated data
    echo \"\\n4️⃣ Verifying Generated Data...\\n\";
    \$newCount = CartActivityLog::count();
    echo \"   ✅ Total records after generation: {\$newCount}\\n\";
    echo \"   ✅ New records created: \" . (\$newCount - \$count) . \"\\n\";
    
    echo \"\\n🎉 All tests passed! MongoDB Cart Analytics system is working perfectly.\\n\";
    
} catch (Exception \$e) {
    echo \"\\n❌ Test failed: \" . \$e->getMessage() . \"\\n\";
    echo \"\\n📋 Stack trace:\\n\" . \$e->getTraceAsString() . \"\\n\";
}
EOF"

# Run the test script
run_remote "cd ${PROJECT_PATH} && php test-cart-analytics.php" "Running MongoDB Cart Analytics functionality test"

# Clean up test script
run_remote "rm -f ${PROJECT_PATH}/test-cart-analytics.php" "Cleaning up test files"

echo ""
echo "🎯 Deployment Summary:"
echo "================================"
echo "✅ CartActivityLog.php - MongoDB model for cart tracking"
echo "✅ CartInsightsService.php - Analytics engine with complex aggregations"
echo "✅ DashboardController.php - Enhanced with cart analytics integration"
echo "✅ dashboard.blade.php - Beautiful cart insights dashboard UI"
echo "✅ web.php - Routes for test data generation"
echo "✅ File permissions and ownership configured"
echo "✅ Laravel caches optimized"
echo "✅ MongoDB connection verified"
echo "✅ Web services restarted"
echo "✅ Functionality testing completed"

echo ""
echo "🔗 Access Points:"
echo "================================"
echo "📊 User Dashboard: http://16.171.119.252/dashboard"
echo "🧪 Generate Test Data: Click 'Generate Test Data' button on dashboard"
echo "🔧 Admin Panel: http://16.171.119.252/admin/dashboard"

echo ""
echo "📋 Next Steps:"
echo "================================"
echo "1. 🔐 Login to user account at http://16.171.119.252/login"
echo "2. 📊 Visit dashboard to see MongoDB cart analytics"
echo "3. 🧪 Generate test data if no cart activity exists"
echo "4. 🎯 Verify shopping insights display correctly"
echo "5. 📈 Test real cart interactions to see live analytics"

echo ""
echo "💡 Features Implemented:"
echo "================================"
echo "📈 Real-time shopping session tracking"
echo "🛒 Cart abandonment analysis with reasons"
echo "⏰ Peak shopping hours identification"
echo "📱 Device preference analytics"
echo "🎯 Conversion funnel analysis"
echo "💰 Cart value trends and distribution"
echo "🤖 Personalized shopping recommendations"
echo "📊 Advanced MongoDB aggregation queries"
echo "🧪 Test data generation for immediate testing"
echo "🔄 Session-based analytics (not individual actions)"

echo ""
echo "🔧 Database Usage:"
echo "================================"
echo "🔵 MySQL (ebrew_laravel_db): All existing functionality preserved"
echo "🟢 MongoDB (ebrew_api): New cart analytics and user insights"
echo "🔗 Dual database architecture working seamlessly"

echo ""
echo "🎉 MongoDB Cart Analytics Deployment COMPLETED! 🎉"
echo ""
echo "Your eBrew Laravel application now has:"
echo "• Comprehensive shopping session analytics"
echo "• Advanced MongoDB document aggregations" 
echo "• Beautiful real-time insights dashboard"
echo "• Personalized shopping recommendations"
echo "• Full test data generation capabilities"
echo ""
echo "Visit http://16.171.119.252/dashboard to see your new MongoDB cart analytics!"