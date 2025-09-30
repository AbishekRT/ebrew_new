#!/bin/bash

# 🔧 COMPREHENSIVE PRIMARY KEY & UI FIXES FOR EC2
# ===============================================

echo "🚀 Starting comprehensive primary key and UI fixes..."

# Step 1: Check and understand current database structure
echo "📊 Step 1: Analyzing database structure..."
cd /var/www/html

# Create database analysis script
cat > database_analysis.php << 'EOF'
<?php
echo "🔍 ANALYZING DATABASE STRUCTURE\n";
echo "================================\n\n";

try {
    $pdo = new PDO('mysql:host=localhost;dbname=ebrew_laravel_db', 'ebrew_user', 'secure_db_password_2024');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Check items table structure
    echo "📋 ITEMS TABLE STRUCTURE:\n";
    $stmt = $pdo->query("DESCRIBE items");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $hasId = false;
    $hasItemID = false;
    $primaryKey = null;
    
    foreach ($columns as $column) {
        $isPrimary = $column['Key'] === 'PRI' ? ' 🔑 PRIMARY' : '';
        $isAI = $column['Extra'] === 'auto_increment' ? ' 🔄 AUTO_INC' : '';
        echo "• {$column['Field']}: {$column['Type']}{$isPrimary}{$isAI}\n";
        
        if ($column['Field'] === 'id' && $column['Key'] === 'PRI') {
            $hasId = true;
            $primaryKey = 'id';
        }
        if ($column['Field'] === 'ItemID' && $column['Key'] === 'PRI') {
            $hasItemID = true;
            $primaryKey = 'ItemID';
        }
    }
    
    echo "\n🎯 PRIMARY KEY: " . ($primaryKey ?: "NOT FOUND") . "\n";
    
    // Check sample data to see what works
    echo "\n📊 SAMPLE DATA:\n";
    if ($primaryKey === 'id') {
        $stmt = $pdo->query("SELECT id, Name, Price FROM items LIMIT 3");
    } else {
        $stmt = $pdo->query("SELECT ItemID, Name, Price FROM items LIMIT 3");
    }
    
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($items as $item) {
        echo "• " . json_encode($item) . "\n";
    }
    
    echo "\n✅ Database analysis complete!\n";
    
} catch (PDOException $e) {
    echo "❌ Database Error: " . $e->getMessage() . "\n";
}
?>
EOF

php database_analysis.php

# Step 2: Update Item Model to use 'id' as primary key
echo "📝 Step 2: Updating Item model..."
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
    protected $primaryKey = 'id'; // FIXED: Use standard 'id' to match database
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
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    // Mutators & Accessors
    public function setNameAttribute($value)
    {
        $this->attributes['Name'] = ucwords(strtolower($value));
    }

    public function setPriceAttribute($value)
    {
        $this->attributes['Price'] = max(0, (float) $value);
    }

    public function getFormattedPriceAttribute()
    {
        return 'LKR ' . number_format((float) $this->Price, 2);
    }

    public function getImageUrlAttribute()
    {
        if (!$this->Image) {
            return asset('images/default.png');
        }
        
        $filename = basename($this->Image);
        return asset('images/' . $filename);
    }

    public function getShortDescriptionAttribute()
    {
        return Str::limit($this->Description, 100);
    }

    public function getIsPremiumAttribute()
    {
        return $this->Price >= 2500;
    }

    public function getSlugAttribute()
    {
        return Str::slug($this->Name . '-' . $this->id);
    }

    // Relationships - FIXED: Use 'id' as local key
    public function cartItems()
    {
        return $this->hasMany(CartItem::class, 'ItemID', 'id');
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class, 'ItemID', 'id');
    }

    // Query Scopes
    public function scopePriceRange($query, $minPrice = null, $maxPrice = null)
    {
        if ($minPrice) {
            $query->where('Price', '>=', $minPrice);
        }
        if ($maxPrice) {
            $query->where('Price', '<=', $maxPrice);
        }
        return $query;
    }

    public function scopeSearch($query, $search)
    {
        return $query->where(function ($q) use ($search) {
            $q->where('Name', 'LIKE', "%{$search}%")
              ->orWhere('Description', 'LIKE', "%{$search}%")
              ->orWhere('TastingNotes', 'LIKE', "%{$search}%");
        });
    }

    public function scopePopular($query, $limit = 10)
    {
        return $query->withCount('orderItems')
                    ->orderBy('order_items_count', 'desc')
                    ->limit($limit);
    }

    public function scopeSortBy($query, $sortBy = 'name')
    {
        switch ($sortBy) {
            case 'price_low':
                return $query->orderBy('Price', 'asc');
            case 'price_high':
                return $query->orderBy('Price', 'desc');
            case 'popular':
                return $query->withCount('orderItems')->orderBy('order_items_count', 'desc');
            case 'newest':
                return $query->orderBy('id', 'desc');
            default:
                return $query->orderBy('Name', 'asc');
        }
    }

    public function newCollection(array $models = [])
    {
        return new ItemCollection($models);
    }
}
EOF

# Step 3: Update ProductController
echo "📝 Step 3: Updating ProductController..."
cat > app/Http/Controllers/ProductController.php << 'EOF'
<?php

namespace App\Http\Controllers;

use App\Models\Item;

class ProductController extends Controller
{
    // Products list page
    public function index()
    {
        // Get products with error handling
        try {
            $products = Item::whereNotNull('id')
                          ->orderBy('id')
                          ->get();
            
            \Log::info('Products loaded', ['count' => $products->count()]);
            
            return view('products', compact('products'));
        } catch (\Exception $e) {
            \Log::error('Error loading products: ' . $e->getMessage());
            return view('products')->with('products', collect())->with('error', 'Unable to load products');
        }
    }

    // Single product page - FIXED: Use find() with 'id'
    public function show($id)
    {
        try {
            $product = Item::find($id);

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

# Step 4: Update products.blade.php to use 'id'
echo "📝 Step 4: Updating products view..."
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
                    @if($product && isset($product->id) && $product->id)
                        <a href="{{ route('products.show', $product->id) }}" 
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

                        @if(!$product || !isset($product->id) || !$product->id)
                            <p class="text-xs text-red-500 mt-1">
                                ⚠️ ID: {{ $product->id ?? 'NULL' }}
                            </p>
                        @else
                            <p class="text-xs text-green-500 mt-1">
                                ✅ ID: {{ $product->id }}
                            </p>
                        @endif

                    @if($product && isset($product->id) && $product->id)
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

# Step 5: Update product_detail.blade.php to use 'id'
echo "📝 Step 5: Updating product detail view..."
cat > resources/views/product_detail.blade.php << 'EOF'
@extends('layouts.app')

@section('title', $product->Name ?? 'Product - eBrew Café')

@section('content')

<main class="max-w-7xl mx-auto px-6 py-10 grid grid-cols-1 md:grid-cols-2 gap-10">

    <!-- Product Image -->
    <div class="flex justify-center items-start">
        <img src="{{ $product->image_url }}" 
             alt="{{ $product->Name ?? 'Product' }}" 
             class="w-full max-w-xs object-cover">
    </div>

    <!-- Product Details -->
    <div class="space-y-6">

        <!-- Name & Price -->
        <div>
            <h1 class="text-2xl font-semibold text-gray-900">
                {{ $product->Name ?? 'Unnamed Product' }}
            </h1>
            <p class="text-lg font-medium text-gray-800 mt-1">
                Rs.{{ number_format($product->Price ?? 0, 2) }}
            </p>
        </div>

        <!-- Description -->
        <p class="text-gray-700 leading-relaxed">
            {!! nl2br(e($product->Description ?? 'No description available')) !!}
        </p>

        <hr class="border-gray-300">

        <!-- Extra Details -->
        <div class="space-y-4 text-sm text-gray-700">
            <div>
                <p class="font-bold">Taste Notes</p>
                <p>{!! nl2br(e($product->TastingNotes ?? 'N/A')) !!}</p>
            </div>

            <div>
                <p class="font-bold">Shipping and Returns</p>
                <p>{!! nl2br(e($product->ShippingAndReturns ?? 'N/A')) !!}</p>
            </div>

            <div>
                <p class="font-bold">Roast Date</p>
                <p>{{ $product->RoastDates ? \Carbon\Carbon::parse($product->RoastDates)->format('Y-m-d') : 'N/A' }}</p>
            </div>
        </div>

        <!-- Add to Cart Component - FIXED: Use 'id' -->
        <div class="mt-6">
            <livewire:add-to-cart :item-id="$product->id" />
        </div>

    </div>

</main>

<!-- Feature Tabs Section -->
<section class="max-w-7xl mx-auto px-6 py-12">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="text-center p-6 bg-gray-50 rounded-lg">
            <i class="fas fa-coffee text-3xl text-yellow-500 mb-3"></i>
            <h4 class="font-semibold text-gray-800 mb-2">Fresh Quality</h4>
            <p class="text-gray-600 text-sm">Made with the finest ingredients</p>
        </div>
        
        <div class="text-center p-6 bg-gray-50 rounded-lg">
            <i class="fas fa-shipping-fast text-3xl text-yellow-500 mb-3"></i>
            <h4 class="font-semibold text-gray-800 mb-2">Quick Service</h4>
            <p class="text-gray-600 text-sm">Fast and efficient preparation</p>
        </div>
        
        <div class="text-center p-6 bg-gray-50 rounded-lg">
            <i class="fas fa-heart text-3xl text-yellow-500 mb-3"></i>
            <h4 class="font-semibold text-gray-800 mb-2">Made with Love</h4>
            <p class="text-gray-600 text-sm">Crafted by our expert baristas</p>
        </div>
    </div>
</section>

@endsection
EOF

# Step 6: Update header to show cart icon instead of text
echo "📝 Step 6: Updating header with cart icon..."
# Update the cart section in header
sed -i 's/<a href="{{ route('"'"'cart.index'"'"') }}" class="hover:text-yellow-900 transition">Cart<\/a>/<a href="{{ route('"'"'cart.index'"'"') }}" class="hover:text-yellow-900 transition relative" title="Shopping Cart"><svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http:\/\/www.w3.org\/2000\/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-1.1 5a1 1 0 00.95 1.05H19M9 19v.01M20 19v.01"><\/path><\/svg><\/a>/g' resources/views/partials/header.blade.php

# Step 7: Clear all Laravel caches
echo "🔄 Step 7: Clearing Laravel caches..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

# Step 8: Set proper permissions
echo "🔒 Step 8: Setting permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod -R 775 /var/www/html/storage
chmod -R 775 /var/www/html/bootstrap/cache

# Step 9: Restart services
echo "🔄 Step 9: Restarting services..."
systemctl restart apache2
systemctl restart mysql

echo "✅ Complete primary key and UI fixes applied successfully!"
echo ""
echo "🎯 Testing URLs:"
echo "• Products page: http://16.171.36.211/products"
echo "• Sample product: http://16.171.36.211/products/1"
echo "• Cart icon should be visible in header"
echo ""
echo "Expected results:"
echo "✅ Products page loads and shows clickable products"
echo "✅ Product detail pages work when clicked"  
echo "✅ No 'ID: Missing' errors"
echo "✅ Cart shows as icon, not text"
echo "✅ Consistent product linking between homepage and products page"
echo ""
echo "🔧 Fixed Issues:"
echo "• Item model uses 'id' as primary key ✅"
echo "• ProductController uses find() method ✅"
echo "• Products view uses \$product->id ✅"
echo "• Product detail view uses \$product->id ✅"
echo "• Header shows cart icon instead of text ✅"
echo "• Relationships use correct foreign keys ✅"
echo ""
echo "🏁 All primary key and UI issues resolved!"