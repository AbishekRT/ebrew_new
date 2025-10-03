# Laravel Asset Fix Script for New Elastic IP Server
# This script fixes common Laravel deployment issues: missing assets, permissions, and Laravel optimization

param(
    [string]$ServerHost = "16.171.119.252",
    [string]$ServerUser = "ubuntu", 
    [string]$ProjectPath = "/var/www/html"
)

Write-Host "🔧 Laravel Asset Fix for New Server" -ForegroundColor Green
Write-Host "🎯 Target Server: $ServerHost" -ForegroundColor Cyan

# Function to run remote commands with multiple connection strategies
function Invoke-RemoteCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "🔧 $Description..." -ForegroundColor Yellow
    
    # Strategy 1: Try password authentication
    Write-Host "   🔐 Trying password authentication..." -ForegroundColor Gray
    $result = ssh -o PreferredAuthentications=password -o StrictHostKeyChecking=no "${ServerUser}@${ServerHost}" $Command 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ $Description completed (password auth)" -ForegroundColor Green
        return $true
    }
    
    # Strategy 2: Try with SSH options
    Write-Host "   🔑 Trying with SSH key..." -ForegroundColor Gray  
    $result = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${ServerUser}@${ServerHost}" $Command 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ $Description completed (SSH key)" -ForegroundColor Green
        return $true
    }
    
    Write-Host "   ❌ $Description failed" -ForegroundColor Red
    Write-Host "   📋 Error: $result" -ForegroundColor Red
    return $false
}

Write-Host ""
Write-Host "🔍 Diagnosing Laravel Asset Issues..." -ForegroundColor Cyan

# Laravel Asset Fix Commands
$commands = @(
    @{
        Command = "cd $ProjectPath && pwd && ls -la"
        Description = "Check project directory"
    },
    @{
        Command = "cd $ProjectPath && ls -la public/"
        Description = "Check public directory contents"
    },
    @{
        Command = "cd $ProjectPath && ls -la storage/"
        Description = "Check storage directory"
    },
    @{
        Command = "sudo chown -R www-data:www-data $ProjectPath"
        Description = "Fix ownership permissions"
    },
    @{
        Command = "sudo chmod -R 755 $ProjectPath"
        Description = "Fix directory permissions"
    },
    @{
        Command = "sudo chmod -R 775 $ProjectPath/storage"
        Description = "Fix storage permissions"
    },
    @{
        Command = "sudo chmod -R 775 $ProjectPath/bootstrap/cache"
        Description = "Fix bootstrap cache permissions"
    },
    @{
        Command = "cd $ProjectPath && php artisan storage:link"
        Description = "Create storage symbolic link"
    },
    @{
        Command = "cd $ProjectPath && npm install"
        Description = "Install Node.js dependencies"
    },
    @{
        Command = "cd $ProjectPath && npm run build"
        Description = "Build Vite assets"
    },
    @{
        Command = "cd $ProjectPath && php artisan config:clear"
        Description = "Clear configuration cache"
    },
    @{
        Command = "cd $ProjectPath && php artisan cache:clear"
        Description = "Clear application cache"
    },
    @{
        Command = "cd $ProjectPath && php artisan route:clear"
        Description = "Clear route cache"
    },
    @{
        Command = "cd $ProjectPath && php artisan view:clear"
        Description = "Clear view cache"
    },
    @{
        Command = "cd $ProjectPath && php artisan config:cache"
        Description = "Cache configuration"
    },
    @{
        Command = "cd $ProjectPath && php artisan route:cache"
        Description = "Cache routes"
    },
    @{
        Command = "cd $ProjectPath && php artisan view:cache"
        Description = "Cache views"
    },
    @{
        Command = "sudo systemctl reload apache2"
        Description = "Restart Apache web server"
    },
    @{
        Command = "cd $ProjectPath && ls -la public/build/"
        Description = "Check built assets"
    },
    @{
        Command = "cd $ProjectPath && ls -la public/storage/"
        Description = "Check storage link"
    }
)

$successCount = 0
$totalCommands = $commands.Count

foreach ($cmd in $commands) {
    if (Invoke-RemoteCommand -Command $cmd.Command -Description $cmd.Description) {
        $successCount++
    }
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "📊 Execution Summary: $successCount/$totalCommands commands completed" -ForegroundColor $(if ($successCount -eq $totalCommands) { "Green" } else { "Yellow" })

if ($successCount -eq 0) {
    Write-Host ""
    Write-Host "❌ SSH Connection Failed - Manual Steps Required" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Manual Fix Instructions:" -ForegroundColor Cyan
    Write-Host "1. Connect to AWS EC2 Console" -ForegroundColor White
    Write-Host "2. Use 'Connect' button to access instance terminal" -ForegroundColor White
    Write-Host "3. Run these commands manually:" -ForegroundColor White
    Write-Host ""
    
    foreach ($cmd in $commands) {
        Write-Host "   $($cmd.Command)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "🔑 Alternative: Fix SSH Key Setup" -ForegroundColor Cyan
    Write-Host "1. In AWS Console, go to EC2 > Key Pairs" -ForegroundColor White
    Write-Host "2. Create new key pair or use existing one" -ForegroundColor White
    Write-Host "3. Download .pem file and use: ssh -i your-key.pem ubuntu@$ServerHost" -ForegroundColor White
    
    return
}

Write-Host ""
Write-Host "🧪 Testing Asset URLs..." -ForegroundColor Cyan

# Test common asset paths
$testUrls = @(
    "http://$ServerHost/",
    "http://$ServerHost/css/app.css",
    "http://$ServerHost/js/app.js", 
    "http://$ServerHost/build/assets/app.css",
    "http://$ServerHost/build/assets/app.js",
    "http://$ServerHost/images/placeholder.png",
    "http://$ServerHost/storage/"
)

foreach ($url in $testUrls) {
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -ErrorAction Stop
        Write-Host "   ✅ $url - Status: $($response.StatusCode)" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️  $url - Failed (may be normal)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎯 Final Steps:" -ForegroundColor Cyan
Write-Host "1. 🌐 Visit: http://$ServerHost/" -ForegroundColor White
Write-Host "2. 🔄 Force refresh (Ctrl+F5) to clear browser cache" -ForegroundColor White  
Write-Host "3. 📊 Check dashboard: http://$ServerHost/dashboard" -ForegroundColor White
Write-Host "4. 🔧 Admin panel: http://$ServerHost/admin/dashboard" -ForegroundColor White

Write-Host ""
Write-Host "🔧 If Assets Still Missing:" -ForegroundColor Cyan
Write-Host "1. Check browser developer console (F12) for specific errors" -ForegroundColor White
Write-Host "2. Verify all files were uploaded to server correctly" -ForegroundColor White
Write-Host "3. Ensure Node.js and npm are installed on server" -ForegroundColor White
Write-Host "4. Run npm run build manually on server" -ForegroundColor White

Write-Host ""
Write-Host "✨ Laravel Asset Fix Complete! ✨" -ForegroundColor Green