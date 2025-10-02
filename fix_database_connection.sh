#!/bin/bash

echo "=== Database Connection Fix ==="
echo "Fixing MySQL connection issues..."

# 1. Check MySQL service status
echo "1. Checking MySQL service..."
sudo systemctl status mysql --no-pager | head -5

# 2. Restart MySQL if needed
echo "2. Restarting MySQL service..."
sudo systemctl restart mysql
sudo systemctl enable mysql

# 3. Test root connection with different passwords
echo "3. Testing MySQL root connections..."
echo "   Testing with 'mypassword'..."
mysql -u root -p'mypassword' -e "SELECT 1 as connection_test;" 2>/dev/null && echo "   ✅ Connected with 'mypassword'" || echo "   ❌ Failed with 'mypassword'"

echo "   Testing with empty password..."
mysql -u root -e "SELECT 1 as connection_test;" 2>/dev/null && echo "   ✅ Connected with no password" || echo "   ❌ Failed with no password"

echo "   Testing with 'password'..."
mysql -u root -p'password' -e "SELECT 1 as connection_test;" 2>/dev/null && echo "   ✅ Connected with 'password'" || echo "   ❌ Failed with 'password'"

# 4. Check if ebrew_db exists
echo "4. Checking database existence..."
for pwd in "" "mypassword" "password"; do
    if [ -z "$pwd" ]; then
        mysql -u root -e "SHOW DATABASES;" 2>/dev/null | grep -q ebrew_db && echo "   ✅ ebrew_db exists (no password)" && break
    else
        mysql -u root -p"$pwd" -e "SHOW DATABASES;" 2>/dev/null | grep -q ebrew_db && echo "   ✅ ebrew_db exists (password: $pwd)" && WORKING_PWD="$pwd" && break
    fi
done

# 5. Create database if it doesn't exist
echo "5. Ensuring ebrew_db database exists..."
if [ -n "$WORKING_PWD" ]; then
    mysql -u root -p"$WORKING_PWD" -e "CREATE DATABASE IF NOT EXISTS ebrew_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
else
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS ebrew_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
fi

# 6. Check users table exists
echo "6. Checking users table..."
if [ -n "$WORKING_PWD" ]; then
    mysql -u root -p"$WORKING_PWD" ebrew_db -e "DESCRIBE users;" 2>/dev/null && echo "   ✅ Users table exists" || echo "   ⚠️ Users table might not exist"
else
    mysql -u root ebrew_db -e "DESCRIBE users;" 2>/dev/null && echo "   ✅ Users table exists" || echo "   ⚠️ Users table might not exist"
fi

echo
echo "=== Database Connection Check Complete ==="
echo "Working MySQL root password: ${WORKING_PWD:-'(no password)'}"
echo "Run the urgent_admin_fix.sh script next"