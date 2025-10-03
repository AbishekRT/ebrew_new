# Upload Local Resources to Server
Write-Host "=== Uploading Local Resources to Server ===" -ForegroundColor Yellow

$serverIP = "16.171.119.252"
$keyPath = "D:\Users\ansyp\Downloads\ebrew-key.pem"
$localPath = "C:\SSP2\eBrewLaravel - Copy"

Write-Host "Uploading resources and config files..." -ForegroundColor Cyan

try {
    # Upload resources directory
    Write-Host "1. Uploading resources directory..." -ForegroundColor White
    & scp -i $keyPath -r "$localPath\resources" ubuntu@${serverIP}:/tmp/
    
    # Upload config files
    Write-Host "2. Uploading config files..." -ForegroundColor White
    & scp -i $keyPath "$localPath\package.json" "$localPath\vite.config.js" "$localPath\tailwind.config.js" ubuntu@${serverIP}:/tmp/
    
    Write-Host "3. Moving files to web directory via SSH..." -ForegroundColor White
    
    $sshCommands = @"
sudo rm -rf /var/www/html/resources
sudo mv /tmp/resources /var/www/html/
sudo mv /tmp/package.json /var/www/html/
sudo mv /tmp/vite.config.js /var/www/html/
sudo mv /tmp/tailwind.config.js /var/www/html/
sudo chown -R www-data:www-data /var/www/html
"@

    Write-Host "Files uploaded. Now run these commands on the server:" -ForegroundColor Green
    Write-Host "ssh -i `"$keyPath`" ubuntu@$serverIP" -ForegroundColor Yellow
    Write-Host ""
    Write-Host $sshCommands -ForegroundColor Gray
    Write-Host ""
    Write-Host "Then run the fix script:" -ForegroundColor Yellow
    Write-Host "bash /var/www/html/fix-assets-and-ui.sh" -ForegroundColor Gray
}
catch {
    Write-Host "Upload failed. Try manual method:" -ForegroundColor Red
    Write-Host "1. Copy resources/ folder contents manually" -ForegroundColor White
    Write-Host "2. Copy package.json, vite.config.js, tailwind.config.js" -ForegroundColor White
    Write-Host "3. Run the fix script on server" -ForegroundColor White
}