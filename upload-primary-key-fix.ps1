# PowerShell script to upload primary key fixes to EC2
Write-Host "🔧 Uploading Primary Key Fixes to EC2..." -ForegroundColor Green

$ec2_ip = "16.171.36.211"
$key_path = "C:\SSP2\pem\ebrew.pem"  # Adjust this path to your actual .pem file location

# Files to upload
$files = @(
    @{
        local = "C:\SSP2\eBrewLaravel - Copy\app\Models\Item.php"
        remote = "/var/www/html/app/Models/Item.php"
    },
    @{
        local = "C:\SSP2\eBrewLaravel - Copy\resources\views\products.blade.php" 
        remote = "/var/www/html/resources/views/products.blade.php"
    },
    @{
        local = "C:\SSP2\eBrewLaravel - Copy\app\Http\Controllers\ProductController.php"
        remote = "/var/www/html/app/Http/Controllers/ProductController.php"
    }
)

Write-Host "📤 Uploading files..." -ForegroundColor Yellow

foreach ($file in $files) {
    Write-Host "   → $($file.local)" -ForegroundColor Cyan
    scp -i $key_path $file.local ubuntu@${ec2_ip}:$file.remote
    if ($LASTEXITCODE -eq 0) {
        Write-Host "     ✅ Uploaded successfully" -ForegroundColor Green
    } else {
        Write-Host "     ❌ Upload failed" -ForegroundColor Red
    }
}

Write-Host "`n🔄 Clearing Laravel caches..." -ForegroundColor Yellow
ssh -i $key_path ubuntu@$ec2_ip "cd /var/www/html && php artisan config:clear && php artisan route:clear && php artisan view:clear && php artisan cache:clear"

Write-Host "`n🎯 Testing the fix..." -ForegroundColor Green
Write-Host "Visit: http://16.171.36.211/products" -ForegroundColor Cyan
Write-Host "The products should now load without UrlGenerationException and clicking on products should work!" -ForegroundColor Green

Write-Host "`n✅ Primary key fix complete!" -ForegroundColor Green
Write-Host "Changes made:" -ForegroundColor Yellow
Write-Host "• Item model now uses ItemID as primary key" -ForegroundColor White
Write-Host "• Products view now uses \$product->ItemID for route generation" -ForegroundColor White  
Write-Host "• ProductController now queries using ItemID properly" -ForegroundColor White
Write-Host "• Relationships updated to use correct foreign key references" -ForegroundColor White