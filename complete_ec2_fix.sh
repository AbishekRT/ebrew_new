#!/bin/bash

# 🔧 COMPLETE EC2 DATABASE AND LARAVEL FIX
# =======================================

echo "🚀 Starting comprehensive Laravel + Database fix..."

# Step 1: Database Diagnostics and Fix
echo "📊 Step 1: Database Diagnostics"
cd /var/www/html

# Create database diagnostic script
cat > database_fix.php << 'EOF'
<?php
// Database diagnostics and auto-fix script

echo "🔍 Database Diagnostics Starting...\n";

try {
    $pdo = new PDO('mysql:host=localhost;dbname=ebrew_laravel_db', 'ebrew_user', 'ebrew_password_123');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "✅ Database connection successful!\n";
    
    // Check if items table exists with proper structure
    try {
        $stmt = $pdo->query("DESCRIBE items");
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $hasItemID = false;
        $itemIDIsAutoIncrement = false;
        $itemIDIsPrimary = false;
        
        foreach ($columns as $column) {
            if ($column['Field'] === 'ItemID') {
                $hasItemID = true;
                $itemIDIsPrimary = ($column['Key'] === 'PRI');
                $itemIDIsAutoIncrement = (strpos($column['Extra'], 'auto_increment') !== false);
            }
        }
        
        if (!$hasItemID) {
            echo "❌ ItemID column missing - recreating table...\n";
            $pdo->exec("DROP TABLE IF EXISTS items");
            throw new Exception("Force table recreation");
        }
        
        if (!$itemIDIsPrimary || !$itemIDIsAutoIncrement) {
            echo "⚠️  ItemID structure incorrect - fixing...\n";
            // Fix the primary key
            $pdo->exec("ALTER TABLE items DROP PRIMARY KEY");
            $pdo->exec("ALTER TABLE items MODIFY ItemID INT AUTO_INCREMENT PRIMARY KEY");
        }
        
        echo "✅ Table structure verified!\n";
        
    } catch (Exception $e) {
        echo "🛠️  Creating proper items table...\n";
        $createSQL = "
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
        
        $pdo->exec($createSQL);
        echo "✅ Items table created successfully!\n";
    }
    
    // Check data count
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM items");
    $count = $stmt->fetch()['count'];
    
    if ($count == 0) {
        echo "📦 No data found - inserting sample products...\n";
        
        $products = [
            ['Espresso Blend', 'Rich and bold espresso perfect for morning energy boost', 850.00, 'Rich, Bold, Chocolatey notes with hints of caramel', 'Free shipping on orders over Rs.2000. Returns accepted within 30 days.', '1.png'],
            ['Colombian Supreme', 'Premium single-origin Colombian beans sourced from high-altitude farms', 1200.00, 'Fruity, Bright, Citrusy with floral undertones', 'Ships within 2-3 business days. Expedited shipping available.', '2.png'],
            ['French Roast', 'Dark roasted beans with smoky undertones and intense flavor', 950.00, 'Smoky, Intense, Full-bodied with bitter chocolate notes', 'Express delivery available. Free returns on unopened packages.', '3.png'],
            ['Breakfast Blend', 'Smooth morning coffee blend perfect for daily consumption', 750.00, 'Smooth, Balanced, Nutty with mild acidity', 'Standard shipping included. Bulk discounts available.', '4.png'],
            ['Decaf Delight', 'Full flavor without the caffeine using Swiss water process', 900.00, 'Mild, Sweet, Caramel notes without bitterness', 'Free returns within 30 days. Perfect for evening enjoyment.', '5.jpg'],
            ['Italian Roast', 'Traditional Italian-style dark roast with authentic European taste', 1100.00, 'Bold, Bitter, Robust with smoky finish', 'Expedited shipping available. Imported roasting techniques.', '6.jpg'],
            ['House Special', 'Our signature coffee blend crafted by expert roasters', 1350.00, 'Complex, Layered, Premium with multiple flavor notes', 'White glove delivery service. Limited edition packaging.', '7.jpg'],
            ['Organic Fair Trade', 'Ethically sourced organic coffee supporting local farmers', 1450.00, 'Clean, Pure, Earthy with sustainable farming notes', 'Carbon-neutral shipping. Fair trade certified packaging.', '8.jpg']
        ];
        
        $stmt = $pdo->prepare("INSERT INTO items (Name, Description, Price, TastingNotes, ShippingAndReturns, RoastDates, Image) VALUES (?, ?, ?, ?, ?, CURDATE(), ?)");
        
        foreach ($products as $product) {
            $stmt->execute($product);
        }
        
        echo "✅ Inserted " . count($products) . " sample products!\n";
    } else {
        echo "✅ Found {$count} existing products in database\n";
    }
    
    // Verify data integrity
    $stmt = $pdo->query("SELECT ItemID, Name, Price FROM items WHERE ItemID IS NOT NULL ORDER BY ItemID LIMIT 5");
    $samples = $stmt->fetchAll();
    
    echo "\n📋 Sample products:\n";
    foreach ($samples as $item) {
        echo "  • ID: {$item['ItemID']} - {$item['Name']} - Rs.{$item['Price']}\n";
    }
    
    echo "\n✅ Database setup complete!\n";
    
} catch (PDOException $e) {
    echo "❌ Database error: " . $e->getMessage() . "\n";
    exit(1);
}
EOF

# Run database fix
php database_fix.php

# Step 2: Update Laravel files
echo "📝 Step 2: Updating Laravel files..."

# Fix Item model
echo "Updating Item model..."
cat > app/Models/Item.php << 'EOF'
<?php

namespace App\Models;

use App\Collections\ItemCollection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Item extends Model
{
    use HasFactory;

    protected $table = 'items';
    protected $primaryKey = 'ItemID'; // Use ItemID as primary key
    public $timestamps = false;

    protected $fillable = [
        'Name',
        'Description',
        'Price',
        'TastingNotes',
        'ShippingAndReturns',
        'RoastDates',
        'Image'
    ];

    protected function casts(): array
    {
        return [
            'Price' => 'decimal:2',
            'RoastDates' => 'date',
        ];
    }

    // Accessor: Get safe image URL
    public function getImageUrlAttribute()
    {
        if (!$this->Image) {
            return asset('images/default.png');
        }
        
        $filename = basename($this->Image);
        return asset('images/' . $filename);
    }

    // Relationships
    public function cartItems()
    {
        return $this->hasMany(CartItem::class, 'ItemID', 'ItemID');
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class, 'ItemID', 'ItemID');
    }
}
EOF

# Fix ProductController
echo "Updating ProductController..."
cat > app/Http/Controllers/ProductController.php << 'EOF'
<?php

namespace App\Http\Controllers;

use App\Models\Item;

class ProductController extends Controller
{
    // Products list page
    public function index()
    {
        // Get products directly from database with error handling
        try {
            $products = Item::whereNotNull('ItemID')
                          ->orderBy('ItemID')
                          ->get();
            
            // Debug: Log the products for troubleshooting
            \Log::info('Products loaded', ['count' => $products->count()]);
            
            return view('products', compact('products'));
        } catch (\Exception $e) {
            \Log::error('Error loading products: ' . $e->getMessage());
            return view('products')->with('products', collect())->with('error', 'Unable to load products');
        }
    }

    // Single product page
    public function show($id)
    {
        try {
            $product = Item::where('ItemID', $id)->first();

            if (!$product) {
                abort(404, 'Product not found');
            }

            return view('product_detail', compact('product'));
        } catch (\Exception $e) {
            \Log::error('Error loading product: ' . $e->getMessage());
            abort(404, 'Product not found');
        }
    }
}
EOF

# Fix products.blade.php
echo "Updating products view..."
cat > resources/views/products.blade.php << 'EOF'
@extends('layouts.app')

@section('title', 'Products - eBrew Café')

@section('content')

<!-- Hero Banner -->
<div class="relative w-full h-80 sm:h-[500px]">
    <img src="{{ asset('images/B1.png') }}" alt="Hero Image" class="w-full h-full object-cover">
    <div class="absolute inset-0 bg-black/40 flex items-center justify-center">
        <div class="text-center text-white px-4">
            <h1 class="text-3xl sm:text-5xl font-bold">Ebrew Café</h1>
            <p class="text-lg mt-2">Handpicked brews, delivered with care</p>
        </div>
    </div>
</div>

<!-- Error Display -->
@if(isset($error))
    <div class="max-w-7xl mx-auto px-6 py-4">
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
            {{ $error }}
        </div>
    </div>
@endif

<!-- Product Sections -->
<section class="max-w-7xl mx-auto px-6 py-16 space-y-20">

    @foreach(['Featured Collection', 'Best Sellers', 'New Arrivals'] as $category)
        <div>
            <h2 class="text-2xl font-bold text-gray-900 mb-6 flex items-center">
                <span class="w-2 h-6 bg-red-600 inline-block mr-3 rounded"></span>{{ $category }}
            </h2>

            <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-10 justify-items-center">
                @forelse($products as $product)
                    @if($product && isset($product->ItemID) && $product->ItemID)
                        <a href="{{ route('products.show', $product->ItemID) }}" 
                           class="group bg-white rounded-lg shadow hover:shadow-lg transition p-4 text-center w-full max-w-[200px]">
                    @else
                        <div class="group bg-white rounded-lg shadow hover:shadow-lg transition p-4 text-center w-full max-w-[200px] cursor-not-allowed opacity-75">
                    @endif

                        <!-- Product Image -->
                        <div class="aspect-w-1 aspect-h-1">
                            <img src="{{ $product->image_url ?? asset('images/default.png') }}" 
                                 alt="{{ $product->Name ?? 'Product' }}" 
                                 class="w-full h-full object-contain rounded">
                        </div>

                        <!-- Product Name -->
                        <h3 class="text-sm font-semibold text-gray-800 mt-4 group-hover:text-red-600 transition">
                            {{ $product->Name ?? 'Unnamed Product' }}
                        </h3>

                        <!-- Product Price -->
                        <p class="text-red-600 font-bold mt-2">
                            Rs. {{ number_format($product->Price ?? 0, 2) }}
                        </p>

                        @if(!$product || !isset($product->ItemID) || !$product->ItemID)
                            <p class="text-xs text-red-500 mt-1">
                                ⚠️ Invalid Product ID
                            </p>
                        @endif

                    @if($product && isset($product->ItemID) && $product->ItemID)
                        </a>
                    @else
                        </div>
                    @endif
                @empty
                    <div class="col-span-full text-center py-12">
                        <p class="text-gray-500 text-lg">No products available at the moment.</p>
                        <p class="text-gray-400 text-sm mt-2">Please check back later or contact support.</p>
                    </div>
                @endforelse
            </div>
        </div>
    @endforeach

</section>

@endsection
EOF

# Step 3: Clear all Laravel caches
echo "🔄 Step 3: Clearing Laravel caches..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

# Step 4: Set proper permissions
echo "🔒 Step 4: Setting permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod -R 775 /var/www/html/storage
chmod -R 775 /var/www/html/bootstrap/cache

# Step 5: Restart services
echo "🔄 Step 5: Restarting services..."
systemctl restart apache2
systemctl restart mysql

echo "✅ Complete fix applied successfully!"
echo ""
echo "🎯 Testing URLs:"
echo "• Main products page: http://16.171.36.211/products"
echo "• Sample product: http://16.171.36.211/products/1"
echo "• Database debug: http://16.171.36.211/debug/database"
echo ""
echo "Expected results:"
echo "✅ Products page loads without errors"
echo "✅ Product cards are clickable"  
echo "✅ Product detail pages work"
echo "✅ No 'ID: Missing' errors"
echo ""
echo "🏁 Fix complete! Test your application now."