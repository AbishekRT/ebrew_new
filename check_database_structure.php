<?php
// Database structure checker
echo "🔍 CHECKING DATABASE STRUCTURE\n";
echo "===============================\n\n";

try {
    $pdo = new PDO('mysql:host=localhost;dbname=ebrew_laravel_db', 'ebrew_user', 'secure_db_password_2024');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Check items table structure
    echo "📋 ITEMS TABLE STRUCTURE:\n";
    echo "-------------------------\n";
    $stmt = $pdo->query("DESCRIBE items");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $hasId = false;
    $hasItemID = false;
    $primaryKey = null;
    
    foreach ($columns as $column) {
        $isPrimary = $column['Key'] === 'PRI' ? ' 🔑 PRIMARY KEY' : '';
        $isAutoIncrement = $column['Extra'] === 'auto_increment' ? ' 🔄 AUTO_INCREMENT' : '';
        echo "• {$column['Field']}: {$column['Type']}{$isPrimary}{$isAutoIncrement}\n";
        
        if ($column['Field'] === 'id') {
            $hasId = true;
            if ($column['Key'] === 'PRI') $primaryKey = 'id';
        }
        if ($column['Field'] === 'ItemID') {
            $hasItemID = true;
            if ($column['Key'] === 'PRI') $primaryKey = 'ItemID';
        }
    }
    
    echo "\n🔍 PRIMARY KEY ANALYSIS:\n";
    echo "-------------------------\n";
    echo "Has 'id' column: " . ($hasId ? "✅ YES" : "❌ NO") . "\n";
    echo "Has 'ItemID' column: " . ($hasItemID ? "✅ YES" : "❌ NO") . "\n";
    echo "Primary Key: " . ($primaryKey ?: "❌ NOT FOUND") . "\n";
    
    // Check sample data
    echo "\n📊 SAMPLE DATA:\n";
    echo "----------------\n";
    
    if ($hasId && !$hasItemID) {
        $stmt = $pdo->query("SELECT id, Name, Price FROM items LIMIT 5");
        echo "Using 'id' column:\n";
    } elseif ($hasItemID && !$hasId) {
        $stmt = $pdo->query("SELECT ItemID, Name, Price FROM items LIMIT 5");
        echo "Using 'ItemID' column:\n";
    } else {
        $stmt = $pdo->query("SELECT * FROM items LIMIT 5");
        echo "Using all columns:\n";
    }
    
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($items as $item) {
        echo "• " . json_encode($item) . "\n";
    }
    
    echo "\n🎯 RECOMMENDATION:\n";
    echo "-------------------\n";
    
    if ($primaryKey === 'id') {
        echo "✅ Database uses 'id' as primary key\n";
        echo "🔧 Fix: Update Laravel model to use 'id' instead of 'ItemID'\n";
        echo "   Change: protected \$primaryKey = 'id';\n";
    } elseif ($primaryKey === 'ItemID') {
        echo "✅ Database uses 'ItemID' as primary key\n";
        echo "🔧 Fix: Database already correct, Laravel model should work\n";
    } else {
        echo "❌ No clear primary key found\n";
        echo "🔧 Fix: Need to set proper primary key on items table\n";
    }
    
} catch (PDOException $e) {
    echo "❌ Database Error: " . $e->getMessage() . "\n";
}
?>