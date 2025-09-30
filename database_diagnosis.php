<?php
// Complete database diagnostics script
// Save as database_check.php and run on EC2

echo "🔍 COMPREHENSIVE DATABASE DIAGNOSTICS\n";
echo "=====================================\n\n";

try {
    // Connect to MySQL
    $pdo = new PDO('mysql:host=localhost;dbname=ebrew_laravel_db', 'ebrew_user', 'ebrew_password_123');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "✅ Database connection successful!\n\n";
    
    // 1. Check if items table exists
    echo "📋 CHECKING TABLE STRUCTURE:\n";
    echo "----------------------------\n";
    
    try {
        $stmt = $pdo->query("DESCRIBE items");
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($columns as $column) {
            $isPrimary = $column['Key'] === 'PRI' ? ' 🔑 PRIMARY KEY' : '';
            $isAutoIncrement = $column['Extra'] === 'auto_increment' ? ' 🔄 AUTO_INCREMENT' : '';
            echo "• {$column['Field']}: {$column['Type']}{$isPrimary}{$isAutoIncrement}\n";
        }
        
        // Check primary key specifically
        $stmt = $pdo->query("SHOW KEYS FROM items WHERE Key_name = 'PRIMARY'");
        $primaryKey = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($primaryKey) {
            echo "\n🔑 Primary Key Column: {$primaryKey['Column_name']}\n";
        } else {
            echo "\n❌ NO PRIMARY KEY FOUND!\n";
        }
        
    } catch (PDOException $e) {
        echo "❌ Items table doesn't exist or error: " . $e->getMessage() . "\n";
        
        // Try to create the table
        echo "\n🛠️  ATTEMPTING TO CREATE ITEMS TABLE...\n";
        $createTable = "
        CREATE TABLE items (
            ItemID INT AUTO_INCREMENT PRIMARY KEY,
            Name VARCHAR(255) NOT NULL,
            Description TEXT,
            Price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            TastingNotes TEXT,
            ShippingAndReturns TEXT,
            RoastDates DATE,
            Image VARCHAR(255),
            created_at TIMESTAMP NULL DEFAULT NULL,
            updated_at TIMESTAMP NULL DEFAULT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
        
        $pdo->exec($createTable);
        echo "✅ Items table created successfully!\n";
    }
    
    echo "\n📊 DATA ANALYSIS:\n";
    echo "-------------------\n";
    
    // 2. Count total rows
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM items");
    $count = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "Total items: {$count['total']}\n";
    
    // 3. Check for NULL ItemIDs
    $stmt = $pdo->query("SELECT COUNT(*) as null_ids FROM items WHERE ItemID IS NULL");
    $nullCount = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "Items with NULL ItemID: {$nullCount['null_ids']}\n";
    
    // 4. Show sample data
    if ($count['total'] > 0) {
        echo "\n📦 SAMPLE DATA (First 5 items):\n";
        echo "--------------------------------\n";
        $stmt = $pdo->query("SELECT ItemID, Name, Price, Image FROM items ORDER BY ItemID LIMIT 5");
        $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($items as $item) {
            echo "ID: {$item['ItemID']} | Name: {$item['Name']} | Price: Rs.{$item['Price']} | Image: {$item['Image']}\n";
        }
    } else {
        echo "\n❌ NO DATA FOUND - Need to seed the database!\n";
        
        echo "\n🌱 SEEDING SAMPLE DATA...\n";
        echo "-------------------------\n";
        
        $sampleItems = [
            ['Espresso Blend', 'Rich and bold espresso perfect for morning energy', 850.00, 'Rich, Bold, Chocolatey', 'Free shipping on orders over Rs.2000', '1.png'],
            ['Colombian Supreme', 'Premium single-origin Colombian beans', 1200.00, 'Fruity, Bright, Citrusy', 'Ships within 2-3 business days', '2.png'],
            ['French Roast', 'Dark roasted beans with smoky undertones', 950.00, 'Smoky, Intense, Full-bodied', 'Express delivery available', '3.png'],
            ['Breakfast Blend', 'Smooth morning coffee blend', 750.00, 'Smooth, Balanced, Nutty', 'Standard shipping included', '4.png'],
            ['Decaf Delight', 'Full flavor without the caffeine', 900.00, 'Mild, Sweet, Caramel', 'Free returns within 30 days', '5.jpg'],
            ['Italian Roast', 'Traditional Italian-style dark roast', 1100.00, 'Bold, Bitter, Robust', 'Expedited shipping available', '6.jpg'],
            ['House Special', 'Our signature coffee blend', 1350.00, 'Complex, Layered, Premium', 'White glove delivery service', '7.jpg'],
            ['Organic Fair Trade', 'Ethically sourced organic coffee', 1450.00, 'Clean, Pure, Earthy', 'Carbon-neutral shipping', '8.jpg']
        ];
        
        $insertStmt = $pdo->prepare("
            INSERT INTO items (Name, Description, Price, TastingNotes, ShippingAndReturns, RoastDates, Image) 
            VALUES (?, ?, ?, ?, ?, CURDATE(), ?)
        ");
        
        foreach ($sampleItems as $item) {
            $insertStmt->execute($item);
        }
        
        echo "✅ Inserted " . count($sampleItems) . " sample items!\n";
        
        // Show the newly inserted data
        echo "\n📦 NEWLY INSERTED DATA:\n";
        echo "------------------------\n";
        $stmt = $pdo->query("SELECT ItemID, Name, Price FROM items ORDER BY ItemID");
        $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($items as $item) {
            echo "ID: {$item['ItemID']} | Name: {$item['Name']} | Price: Rs.{$item['Price']}\n";
        }
    }
    
    echo "\n🔧 LARAVEL INTEGRATION CHECK:\n";
    echo "------------------------------\n";
    
    // 5. Test Laravel's Item model would work
    $stmt = $pdo->query("SELECT ItemID, Name FROM items WHERE ItemID IS NOT NULL LIMIT 3");
    $testItems = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($testItems) > 0) {
        echo "✅ Valid ItemIDs found for Laravel routing:\n";
        foreach ($testItems as $item) {
            echo "   → /products/{$item['ItemID']} - {$item['Name']}\n";
        }
    } else {
        echo "❌ No valid ItemIDs - Laravel routing will fail!\n";
    }
    
    echo "\n🎯 RECOMMENDATIONS:\n";
    echo "-------------------\n";
    
    if ($count['total'] == 0) {
        echo "1. ✅ Database has been seeded with sample data\n";
        echo "2. 🔄 Clear Laravel cache: php artisan cache:clear\n";
        echo "3. 🌐 Test: http://16.171.36.211/products\n";
    } else {
        echo "1. ✅ Database has data\n";
        echo "2. 🔍 Check Laravel Item model primary key setting\n";
        echo "3. 🔄 Clear Laravel cache if needed\n";
    }
    
} catch (PDOException $e) {
    echo "❌ Database Error: " . $e->getMessage() . "\n";
    echo "\nPossible solutions:\n";
    echo "1. Check MySQL service: sudo systemctl status mysql\n";
    echo "2. Check database exists: mysql -u ebrew_user -p -e 'SHOW DATABASES;'\n";
    echo "3. Verify credentials in Laravel .env file\n";
}

echo "\n" . str_repeat("=", 50) . "\n";
echo "🏁 DIAGNOSIS COMPLETE\n";
?>