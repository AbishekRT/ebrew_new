#!/bin/bash

echo "=== Diagnose Database Connection Issues ==="
echo "Finding the correct database credentials..."

cd /var/www/html

# 1. Test what database connections actually work
echo "1. Testing different MySQL connections..."
echo "   Testing root with no password..."
mysql -u root -e "SHOW DATABASES;" 2>/dev/null && echo "   ✅ Root (no password) works" || echo "   ❌ Root (no password) failed"

echo "   Testing root with 'password'..."
mysql -u root -p'password' -e "SHOW DATABASES;" 2>/dev/null && echo "   ✅ Root (password) works" || echo "   ❌ Root (password) failed"

echo "   Testing root with 'mypassword'..."
mysql -u root -p'mypassword' -e "SHOW DATABASES;" 2>/dev/null && echo "   ✅ Root (mypassword) works" || echo "   ❌ Root (mypassword) failed"

# 2. Check what databases actually exist
echo "2. Checking what databases exist..."
for pwd in "" "password" "mypassword"; do
    if [ -z "$pwd" ]; then
        echo "   With root (no password):"
        mysql -u root -e "SHOW DATABASES;" 2>/dev/null | grep -E "(ebrew|laravel)" || echo "     No ebrew/laravel databases found"
    else
        echo "   With root ($pwd):"
        mysql -u root -p"$pwd" -e "SHOW DATABASES;" 2>/dev/null | grep -E "(ebrew|laravel)" || echo "     No ebrew/laravel databases found or connection failed"
    fi
done

# 3. Check if ebrew_user exists
echo "3. Checking if ebrew_user exists..."
for pwd in "" "password" "mypassword"; do
    if [ -z "$pwd" ]; then
        mysql -u root -e "SELECT User FROM mysql.user WHERE User = 'ebrew_user';" 2>/dev/null | grep ebrew_user && echo "   ✅ ebrew_user exists" || echo "   ❌ ebrew_user not found"
    else
        mysql -u root -p"$pwd" -e "SELECT User FROM mysql.user WHERE User = 'ebrew_user';" 2>/dev/null | grep ebrew_user && echo "   ✅ ebrew_user exists" || echo "   ❌ ebrew_user not found"
    fi
done

# 4. Check Laravel's current database test
echo "4. Testing Laravel's current database connection..."
php artisan tinker --execute="
try {
    \$config = config('database.connections.mysql');
    echo 'Current Laravel DB config:' . PHP_EOL;
    echo 'Database: ' . \$config['database'] . PHP_EOL;
    echo 'Username: ' . \$config['username'] . PHP_EOL;
    echo 'Password: ' . (empty(\$config['password']) ? '(empty)' : '(set)') . PHP_EOL;
    echo 'Testing connection...' . PHP_EOL;
    \$pdo = DB::connection()->getPdo();
    echo 'Connection: SUCCESS' . PHP_EOL;
    \$itemCount = \App\Models\Item::count();
    echo 'Items count: ' . \$itemCount . PHP_EOL;
    \$userCount = \App\Models\User::count();
    echo 'Users count: ' . \$userCount . PHP_EOL;
} catch (Exception \$e) {
    echo 'Laravel DB Error: ' . \$e->getMessage() . PHP_EOL;
}
exit;
" 2>/dev/null || echo "   Laravel database test failed"

# 5. Check admin user in whatever database works
echo "5. Looking for admin user in any working database..."
for db in "ebrew_db" "ebrew_laravel_db" "laravel"; do
    for pwd in "" "password" "mypassword"; do
        if [ -z "$pwd" ]; then
            echo "   Checking $db with root (no password)..."
            mysql -u root $db -e "SELECT id, name, email, role, is_admin FROM users WHERE email = 'abhishake.a@gmail.com';" 2>/dev/null && echo "   ✅ Found admin in $db!" || echo "   ❌ Not found in $db"
        else
            echo "   Checking $db with root ($pwd)..."
            mysql -u root -p"$pwd" $db -e "SELECT id, name, email, role, is_admin FROM users WHERE email = 'abhishake.a@gmail.com';" 2>/dev/null && echo "   ✅ Found admin in $db!" || echo "   ❌ Not found in $db"
        fi
    done
done

echo
echo "=== Database Diagnosis Complete ==="
echo "This will show us the correct database and credentials to use"