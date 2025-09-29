# Complete Laravel Cache Clear & Optimization Commands

## Single Command - Clear Everything and Optimize

```bash
cd /var/www/html && sudo -u www-data php artisan config:clear && sudo -u www-data php artisan route:clear && sudo -u www-data php artisan view:clear && sudo -u www-data php artisan cache:clear && sudo -u www-data composer dump-autoload --optimize && sudo -u www-data php artisan config:cache && sudo -u www-data php artisan route:cache && sudo -u www-data php artisan view:cache && sudo systemctl restart apache2 && echo "✅ Laravel fully optimized and Apache restarted"
```

## Or Step by Step Commands:

### 1. Navigate to Laravel Directory

```bash
cd /var/www/html
```

### 2. Clear All Caches

```bash
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan route:clear
sudo -u www-data php artisan view:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan event:clear
```

### 3. Regenerate Autoloads

```bash
sudo -u www-data composer dump-autoload --optimize
```

### 4. Cache for Production

```bash
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan route:cache
sudo -u www-data php artisan view:cache
```

### 5. Test Database Connection

```bash
sudo -u www-data php artisan tinker --execute="DB::connection()->getPdo(); echo 'MySQL Connected Successfully';"
```

### 6. Restart Apache

```bash
sudo systemctl restart apache2
```

### 7. Check Application Status

```bash
curl -I http://localhost/
```

## Database Connection Test Commands:

### Test MySQL from Command Line:

```bash
# Replace with your actual credentials from .env
mysql -u ebrew_user -p -h 127.0.0.1 ebrew_laravel_db
```

### Test Laravel Database Connection:

```bash
cd /var/www/html
sudo -u www-data php artisan tinker
# In tinker, run:
DB::connection()->getPdo();
# Should return PDO object without errors
```

## Monitor Logs in Real-Time:

```bash
# Open in one terminal to watch for new errors
tail -f /var/www/html/storage/logs/laravel.log

# In another terminal, test your FAQ page:
curl http://16.171.36.211/faq
```

## Quick Environment Check:

```bash
cd /var/www/html && echo "APP_KEY: $(grep APP_KEY .env)" && echo "DB_CONNECTION: $(grep DB_CONNECTION .env)" && echo "DB_HOST: $(grep DB_HOST .env)" && echo "DB_DATABASE: $(grep DB_DATABASE .env)"
```
