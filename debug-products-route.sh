#!/bin/bash

# Debug Products Route Issue
# This script will help identify the exact cause of the UrlGenerationException

set -e

echo "🔍 DEBUGGING: Products Route UrlGenerationException"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_PATH="/var/www/html"

echo -e "${BLUE}🗃️  Step 1: Check database and items table${NC}"
cd $PROJECT_PATH
php artisan tinker --execute="
try {
    \$itemCount = \App\Models\Item::count();
    echo '📊 Total items in database: ' . \$itemCount . PHP_EOL;
    
    if (\$itemCount > 0) {
        \$items = \App\Models\Item::take(3)->get();
        echo '🔍 Sample items:' . PHP_EOL;
        foreach (\$items as \$item) {
            echo '  - ID: ' . (\$item->id ?? 'NULL') . ', Name: ' . (\$item->Name ?? 'NULL') . PHP_EOL;
        }
        
        \$firstItem = \$items->first();
        if (\$firstItem && \$firstItem->id) {
            echo '✅ First item has valid ID: ' . \$firstItem->id . PHP_EOL;
            
            // Test route generation
            try {
                \$url = route('products.show', \$firstItem->id);
                echo '✅ Route generation works: ' . \$url . PHP_EOL;
            } catch (Exception \$e) {
                echo '❌ Route generation failed: ' . \$e->getMessage() . PHP_EOL;
            }
        } else {
            echo '❌ First item has no ID or is null' . PHP_EOL;
        }
    } else {
        echo '❌ No items found in database' . PHP_EOL;
    }
} catch (Exception \$e) {
    echo '❌ Database error: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n${BLUE}🎯 Step 2: Check route registration${NC}"
cd $PROJECT_PATH
echo "Products routes:"
php artisan route:list | grep products || echo "No products routes found"

echo -e "\n${BLUE}🔍 Step 3: Test ProductController directly${NC}"
cd $PROJECT_PATH
echo "Testing ProductController index method:"
php -r "
require_once 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';

try {
    \$controller = new App\Http\Controllers\ProductController();
    \$response = \$controller->index();
    echo '✅ ProductController index method works' . PHP_EOL;
} catch (Exception \$e) {
    echo '❌ ProductController error: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n${BLUE}📄 Step 4: Create temporary debug products view${NC}"
cd $PROJECT_PATH

# Create a temporary debug version of products.blade.php
cat > resources/views/products_debug.blade.php << 'EOF'
@extends('layouts.app')

@section('title', 'Products Debug - eBrew Café')

@section('content')

<div class="container mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold mb-6">Products Debug Information</h1>
    
    <div class="bg-gray-100 p-4 rounded mb-6">
        <h2 class="text-xl font-semibold mb-2">Debug Info:</h2>
        <p><strong>Products count:</strong> {{ count($products) }}</p>
        <p><strong>Products type:</strong> {{ get_class($products) }}</p>
    </div>

    @if(count($products) > 0)
        <div class="mb-6">
            <h2 class="text-xl font-semibold mb-4">First Product Details:</h2>
            @php $firstProduct = $products->first(); @endphp
            <div class="bg-blue-100 p-4 rounded">
                <p><strong>ID:</strong> {{ $firstProduct->id ?? 'NULL' }}</p>
                <p><strong>Name:</strong> {{ $firstProduct->Name ?? 'NULL' }}</p>
                <p><strong>Price:</strong> {{ $firstProduct->Price ?? 'NULL' }}</p>
                <p><strong>All attributes:</strong></p>
                <pre>{{ print_r($firstProduct->getAttributes(), true) }}</pre>
            </div>
        </div>

        <h2 class="text-xl font-semibold mb-4">All Products (Safe Links):</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            @foreach($products as $product)
                <div class="border p-4 rounded">
                    <p><strong>ID:</strong> {{ $product->id ?? 'NULL' }}</p>
                    <p><strong>Name:</strong> {{ $product->Name ?? 'Unnamed' }}</p>
                    <p><strong>Price:</strong> Rs. {{ number_format($product->Price ?? 0, 2) }}</p>
                    
                    @if($product->id)
                        <p><strong>Route URL:</strong> 
                            @try
                                {{ route('products.show', $product->id) }}
                            @catch(Exception $e)
                                <span class="text-red-500">Route Error: {{ $e->getMessage() }}</span>
                            @endtry
                        </p>
                        <a href="{{ route('products.show', $product->id) }}" class="bg-blue-500 text-white px-4 py-2 rounded">
                            View Product
                        </a>
                    @else
                        <p class="text-red-500">No ID - Cannot create route</p>
                    @endif
                </div>
            @endforeach
        </div>
    @else
        <div class="bg-red-100 p-4 rounded">
            <h2 class="text-xl font-semibold text-red-800">No Products Found</h2>
            <p>The products collection is empty. Check database seeding.</p>
        </div>
    @endif
</div>

@endsection
EOF

echo -e "${GREEN}✅ Debug view created${NC}"

echo -e "\n${BLUE}🌐 Step 5: Create debug route${NC}"
cd $PROJECT_PATH

# Add debug route temporarily
echo "
// Temporary debug route - remove after fixing
Route::get('/products/debug', [App\Http\Controllers\ProductController::class, 'index'])
    ->name('products.debug');
" >> routes/web.php

echo -e "${GREEN}✅ Debug route added${NC}"

echo -e "\n${BLUE}🔄 Step 6: Clear caches${NC}"
cd $PROJECT_PATH
php artisan route:clear
php artisan view:clear
echo -e "${GREEN}✅ Caches cleared${NC}"

echo -e "\n${BLUE}🧪 Step 7: Test the debug page${NC}"
echo "Testing debug URL:"
curl -s -o /dev/null -w "Debug page: %{http_code}\n" "http://localhost/products/debug"

echo -e "\n${GREEN}🏁 Debug Setup Complete!${NC}"
echo "================================="
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Visit: http://ec2-16-171-36-211.eu-north-1.compute.amazonaws.com/products/debug"
echo "2. Check the debug information displayed"
echo "3. Look for:"
echo "   - Products count (should be > 0)"
echo "   - First product ID (should not be NULL)"
echo "   - Route generation errors"
echo ""
echo -e "${BLUE}💡 Common Issues:${NC}"
echo "- Empty database (no products)"
echo "- Products with NULL ids"
echo "- Route cache problems"
echo "- Missing route definition"
echo ""
echo -e "${GREEN}🎯 This will show exactly what's wrong!${NC}"