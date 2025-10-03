# Laravel Asset Fix Script for New Elastic IP Server
param(
    [string]$ServerHost = "16.171.119.252",
    [string]$ServerUser = "ubuntu", 
    [string]$ProjectPath = "/var/www/html"
)

Write-Host "Laravel Asset Fix for New Server" -ForegroundColor Green
Write-Host "Target Server: $ServerHost" -ForegroundColor Cyan

# Function to run remote commands with multiple connection strategies
function Invoke-RemoteCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "Running: $Description..." -ForegroundColor Yellow
    
    # Try password authentication first
    $result = ssh -o PreferredAuthentications=password -o StrictHostKeyChecking=no "${ServerUser}@${ServerHost}" $Command 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   SUCCESS: $Description completed" -ForegroundColor Green
        return $true
    }
    
    # Try with SSH key
    $result = ssh -o StrictHostKeyChecking=no "${ServerUser}@${ServerHost}" $Command 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   SUCCESS: $Description completed" -ForegroundColor Green
        return $true
    }
    
    Write-Host "   FAILED: $Description" -ForegroundColor Red
    return $false
}

Write-Host ""
Write-Host "Fixing Laravel Asset Issues..." -ForegroundColor Cyan

# Core Laravel asset fix commands
$commands = @(
    "sudo chown -R www-data:www-data $ProjectPath",
    "sudo chmod -R 755 $ProjectPath", 
    "sudo chmod -R 775 $ProjectPath/storage",
    "sudo chmod -R 775 $ProjectPath/bootstrap/cache",
    "cd $ProjectPath && php artisan storage:link",
    "cd $ProjectPath && php artisan config:clear",
    "cd $ProjectPath && php artisan cache:clear",
    "cd $ProjectPath && php artisan route:clear", 
    "cd $ProjectPath && php artisan view:clear",
    "cd $ProjectPath && npm install",
    "cd $ProjectPath && npm run build",
    "cd $ProjectPath && php artisan config:cache",
    "sudo systemctl reload apache2"
)

$successCount = 0
foreach ($cmd in $commands) {
    if (Invoke-RemoteCommand -Command $cmd -Description "Laravel Fix Step") {
        $successCount++
    }
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "Commands completed: $successCount/$($commands.Count)" -ForegroundColor Yellow

if ($successCount -eq 0) {
    Write-Host ""
    Write-Host "SSH Connection Failed - Use AWS Console" -ForegroundColor Red
    Write-Host "Manual Steps:" -ForegroundColor Cyan
    Write-Host "1. Go to AWS EC2 Console" -ForegroundColor White
    Write-Host "2. Select your instance and click Connect" -ForegroundColor White
    Write-Host "3. Use Session Manager or EC2 Instance Connect" -ForegroundColor White
    Write-Host "4. Run these commands one by one:" -ForegroundColor White
    Write-Host ""
    
    foreach ($cmd in $commands) {
        Write-Host "   $cmd" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Testing asset accessibility..." -ForegroundColor Cyan

# Test if main page loads
try {
    $response = Invoke-WebRequest -Uri "http://$ServerHost/" -TimeoutSec 10
    Write-Host "SUCCESS: Main page loads (Status: $($response.StatusCode))" -ForegroundColor Green
}
catch {
    Write-Host "FAILED: Main page not accessible" -ForegroundColor Red
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Visit: http://$ServerHost/" -ForegroundColor White
Write-Host "2. Press Ctrl+F5 to force refresh and clear cache" -ForegroundColor White  
Write-Host "3. Check browser console (F12) for any remaining errors" -ForegroundColor White
Write-Host "4. Dashboard: http://$ServerHost/dashboard" -ForegroundColor White

Write-Host ""
Write-Host "Laravel Asset Fix Complete!" -ForegroundColor Green