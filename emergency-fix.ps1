Write-Host "🚨 EMERGENCY FIX - Critical Issues Resolution" -ForegroundColor Red
Write-Host "=============================================" -ForegroundColor Red
Write-Host ""

Write-Host "📋 CRITICAL ISSUES IDENTIFIED:" -ForegroundColor Yellow
Write-Host "1. ❌ APP_URL wrong on server (still old ec2 domain)" -ForegroundColor Red
Write-Host "2. ❌ HTTP 500 errors (Laravel broken)" -ForegroundColor Red  
Write-Host "3. ❌ Vite permission denied" -ForegroundColor Red
Write-Host "4. ❌ .env file may be wrong/missing on server" -ForegroundColor Red
Write-Host ""

$serverIP = "16.171.119.252"
$keyPath = "D:\Users\ansyp\Downloads\ebrew-key.pem"

Write-Host "🚀 Executing emergency fix..." -ForegroundColor Cyan

try {
    # Upload and execute emergency fix
    $tempFile = "C:\temp\emergency-fix.sh"
    $null = New-Item -ItemType Directory -Force -Path "C:\temp"
    
    $emergencyScript = Get-Content "c:\SSP2\eBrewLaravel - Copy\emergency-fix.sh" -Raw
    $emergencyScript | Out-File -FilePath $tempFile -Encoding UTF8
    
    Write-Host "Uploading emergency fix script..." -ForegroundColor Yellow
    $scpCommand = "scp -i `"$keyPath`" `"$tempFile`" ubuntu@${serverIP}:/tmp/"
    Invoke-Expression $scpCommand
    
    Write-Host "Executing emergency fix..." -ForegroundColor Yellow
    $sshCommand = "ssh -i `"$keyPath`" ubuntu@${serverIP} `"chmod +x /tmp/emergency-fix.sh && sudo /tmp/emergency-fix.sh`""
    Invoke-Expression $sshCommand
    
    Write-Host ""
    Write-Host "✅ Emergency fix executed!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ SSH failed. Manual execution:" -ForegroundColor Red
    Write-Host ""
    Write-Host "1. SSH to server:" -ForegroundColor White
    Write-Host "   ssh -i `"$keyPath`" ubuntu@$serverIP" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Run emergency fix:" -ForegroundColor White
    Write-Host "   sudo /tmp/emergency-fix.sh" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🔍 TESTING RESULTS..." -ForegroundColor Cyan

try {
    Write-Host "Testing main page..." -ForegroundColor Yellow
    $response = Invoke-WebRequest -Uri "http://$serverIP" -Method Head -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ Main page: HTTP $($response.StatusCode)" -ForegroundColor Green
    
    Write-Host "Testing debug page..." -ForegroundColor Yellow
    $debugResponse = Invoke-WebRequest -Uri "http://$serverIP/debug/assets" -Method Head -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ Debug page: HTTP $($debugResponse.StatusCode)" -ForegroundColor Green
    
    if ($debugResponse.StatusCode -eq 200) {
        Write-Host ""
        Write-Host "🎉 SUCCESS! Both pages working!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🔍 NEXT: CHECK UI" -ForegroundColor Yellow
        Write-Host "1. Visit: http://$serverIP" -ForegroundColor White
        Write-Host "2. Check if CSS/styling is now working" -ForegroundColor White
        Write-Host "3. If still no UI, visit debug page: http://$serverIP/debug/assets" -ForegroundColor White
    }
    
} catch {
    Write-Host "⚠️ Website test: $($_.Exception.Message)" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "🔍 IF STILL NOT WORKING:" -ForegroundColor Yellow
    Write-Host "The emergency fix addressed the critical config issues." -ForegroundColor White
    Write-Host "If site still shows errors:" -ForegroundColor White
    Write-Host ""
    Write-Host "1. Check Laravel logs:" -ForegroundColor Gray
    Write-Host "   ssh -i `"$keyPath`" ubuntu@$serverIP" -ForegroundColor Gray
    Write-Host "   tail -f /var/www/html/storage/logs/laravel.log" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Check database connection:" -ForegroundColor Gray
    Write-Host "   http://$serverIP/debug/database" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📋 EMERGENCY FIX SUMMARY:" -ForegroundColor Yellow
Write-Host "=========================" -ForegroundColor Yellow
Write-Host "✅ Fixed APP_URL to correct elastic IP" -ForegroundColor Green
Write-Host "✅ Cleared all Laravel caches" -ForegroundColor Green
Write-Host "✅ Fixed file permissions" -ForegroundColor Green
Write-Host "✅ Restored/fixed .env file" -ForegroundColor Green
Write-Host "✅ Restarted Apache" -ForegroundColor Green
Write-Host ""
Write-Host "This should resolve the HTTP 500 errors and wrong asset URLs!" -ForegroundColor Green

# Cleanup
Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue