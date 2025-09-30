<?php
// Database verification script to check ItemID values
// Save this as check_items.php and upload to EC2

try {
    // Database connection
    $pdo = new PDO('mysql:host=localhost;dbname=ebrew_laravel_db', 'ebrew_user', 'ebrew_password_123');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "<h2>🔍 Item Database Analysis</h2>\n";
    
    // Check table structure
    $stmt = $pdo->query("DESCRIBE items");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<h3>📋 Table Structure:</h3>\n";
    foreach ($columns as $column) {
        $isPrimary = $column['Key'] === 'PRI' ? ' ⭐ (PRIMARY KEY)' : '';
        echo "• {$column['Field']} - {$column['Type']}{$isPrimary}<br>\n";
    }
    
    // Check data
    $stmt = $pdo->query("SELECT ItemID, Name, Price FROM items ORDER BY ItemID LIMIT 10");
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<h3>📦 Sample Items:</h3>\n";
    if (empty($items)) {
        echo "❌ No items found in database!<br>\n";
    } else {
        foreach ($items as $item) {
            echo "• ID: {$item['ItemID']} - {$item['Name']} - Rs.{$item['Price']}<br>\n";
        }
    }
    
    // Count total items
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM items");
    $count = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "<h3>📊 Total Items: {$count['total']}</h3>\n";
    
    // Check for null ItemIDs
    $stmt = $pdo->query("SELECT COUNT(*) as null_ids FROM items WHERE ItemID IS NULL");
    $nullCount = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "<h3>⚠️  Items with NULL ItemID: {$nullCount['null_ids']}</h3>\n";
    
} catch (PDOException $e) {
    echo "❌ Database Error: " . $e->getMessage() . "\n";
}
?>