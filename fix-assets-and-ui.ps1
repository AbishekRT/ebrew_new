# Fix Assets and UI for Laravel Application
# This script fixes the missing CSS/JS assets issue after IP migration

Write-Host "=== Laravel Asset Fix Script ===" -ForegroundColor Yellow
Write-Host "Fixing UI/CSS/JS issues after elastic IP migration" -ForegroundColor Green

# Step 1: Connect to server and fix permissions
Write-Host "`n1. Fixing server permissions and clearing npm cache..." -ForegroundColor Cyan

$commands = @"
# Fix ownership and permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Clear npm cache and node_modules completely
sudo rm -rf /var/www/html/node_modules
sudo rm -rf /var/www/html/package-lock.json
sudo rm -rf /home/ubuntu/.npm
sudo rm -rf /var/www/.npm

# Clear any vite cache
sudo rm -rf /var/www/html/public/build
sudo rm -rf /var/www/html/node_modules/.vite*

# Create fresh build directory
sudo mkdir -p /var/www/html/public/build
sudo chown -R www-data:www-data /var/www/html/public/build

# Set proper Node.js environment
export NPM_CONFIG_CACHE=/tmp/.npm
export NODE_ENV=production

# Install dependencies with proper permissions
cd /var/www/html
sudo -u www-data npm cache clean --force
sudo -u www-data npm install --no-audit --no-fund --production=false

# Build assets
sudo -u www-data npm run build

# Final permission fix
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Restart Apache
sudo systemctl restart apache2

echo "Build completed successfully!"
"@

# Write commands to temporary file
$tempFile = "/tmp/fix_assets.sh"
$commands | Out-File -FilePath $tempFile -Encoding UTF8

Write-Host "Commands prepared. Run this next:" -ForegroundColor Yellow
Write-Host "ssh -i `"D:\Users\ansyp\Downloads\ebrew-key.pem`" ubuntu@16.171.119.252" -ForegroundColor White
Write-Host ""
Write-Host "Then copy and paste these commands:" -ForegroundColor Yellow
Write-Host $commands -ForegroundColor Gray

Write-Host "`n=== OR manually execute these steps ===" -ForegroundColor Yellow
Write-Host "1. Clear all npm/node caches and modules" -ForegroundColor White
Write-Host "2. Fix ownership (www-data:www-data)" -ForegroundColor White
Write-Host "3. Install npm packages fresh" -ForegroundColor White
Write-Host "4. Build with 'npm run build'" -ForegroundColor White
Write-Host "5. Restart Apache" -ForegroundColor White

Write-Host "`nAfter running, test: http://16.171.119.252" -ForegroundColor Green