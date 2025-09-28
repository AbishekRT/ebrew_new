<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Item;
use App\Models\Product;
use Illuminate\Support\Facades\DB;

class ProductSeeder extends Seeder
{
    public function run()
    {
        // Clear existing data
        Item::truncate();
        Product::truncate();

        // Coffee Products Data
        $coffeeProducts = [
            [
                'name' => 'Espresso Blend',
                'description' => 'Rich and bold espresso perfect for morning energy. A carefully crafted blend of premium Arabica beans with notes of dark chocolate and caramel.',
                'price' => 24.99,
                'category' => 'Coffee',
                'image' => 'images/1.png',
                'stock' => 50
            ],
            [
                'name' => 'Colombian Supreme',
                'description' => 'Single-origin Colombian coffee with bright acidity and fruity undertones. Grown in the high-altitude regions of Huila.',
                'price' => 28.99,
                'category' => 'Coffee',
                'image' => 'images/2.png',
                'stock' => 35
            ],
            [
                'name' => 'French Roast Dark',
                'description' => 'Bold and smoky French roast with intense flavors. Perfect for those who love strong, dark coffee.',
                'price' => 22.99,
                'category' => 'Coffee',
                'image' => 'images/3.png',
                'stock' => 40
            ],
            [
                'name' => 'Ethiopia Yirgacheffe',
                'description' => 'Light roast Ethiopian coffee with floral and citrus notes. Wine-like acidity with a clean finish.',
                'price' => 32.99,
                'category' => 'Coffee',
                'image' => 'images/4.png',
                'stock' => 25
            ],
            [
                'name' => 'Brazilian Santos',
                'description' => 'Medium roast Brazilian coffee with nutty and chocolate flavors. Smooth and well-balanced.',
                'price' => 26.99,
                'category' => 'Coffee',
                'image' => 'images/5.jpg',
                'stock' => 45
            ],
            [
                'name' => 'Guatemala Antigua',
                'description' => 'Full-bodied Guatemalan coffee with spicy and smoky characteristics. Grown in volcanic soil.',
                'price' => 30.99,
                'category' => 'Coffee',
                'image' => 'images/6.jpg',
                'stock' => 30
            ]
        ];

        // Beverage Products Data
        $beverageProducts = [
            [
                'name' => 'Cold Brew Concentrate',
                'description' => 'Smooth and refreshing cold brew concentrate. Just add water or milk for the perfect iced coffee.',
                'price' => 18.99,
                'category' => 'Beverages',
                'image' => 'images/B1.png',
                'stock' => 60
            ],
            [
                'name' => 'Chai Tea Latte Mix',
                'description' => 'Aromatic chai blend with warming spices. Perfect for cozy afternoons.',
                'price' => 16.99,
                'category' => 'Beverages',
                'image' => 'images/B2.png',
                'stock' => 40
            ],
            [
                'name' => 'Matcha Green Tea Powder',
                'description' => 'Premium Japanese matcha powder. Rich in antioxidants and perfect for lattes.',
                'price' => 34.99,
                'category' => 'Beverages',
                'image' => 'images/B3.jpg',
                'stock' => 20
            ]
        ];

        // Insert Products using Product model
        foreach ($coffeeProducts as $index => $product) {
            Product::create([
                'id' => $index + 1,
                'name' => $product['name'],
                'description' => $product['description'],
                'price' => $product['price'],
                'category' => $product['category'],
                'image_path' => $product['image'],
                'stock_quantity' => $product['stock'],
                'is_featured' => $index < 3, // First 3 products are featured
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        foreach ($beverageProducts as $index => $product) {
            Product::create([
                'id' => $index + 7,
                'name' => $product['name'],
                'description' => $product['description'],
                'price' => $product['price'],
                'category' => $product['category'],
                'image_path' => $product['image'],
                'stock_quantity' => $product['stock'],
                'is_featured' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // Insert Items using Item model (legacy support)
        $itemsData = [
            [
                'ItemID' => 1,
                'Name' => 'Espresso Blend Premium',
                'Description' => 'Rich and bold espresso perfect for morning energy. Premium Arabica blend with dark chocolate notes.',
                'Price' => 24.99,
                'Category' => 'Coffee',
                'image_url' => 'images/1.png',
                'Stock' => 50
            ],
            [
                'ItemID' => 2,
                'Name' => 'Colombian Supreme Single Origin',
                'Description' => 'Single-origin Colombian coffee with bright acidity and fruity undertones from Huila region.',
                'Price' => 28.99,
                'Category' => 'Coffee',
                'image_url' => 'images/2.png',
                'Stock' => 35
            ],
            [
                'ItemID' => 3,
                'Name' => 'French Roast Dark & Bold',
                'Description' => 'Bold and smoky French roast with intense flavors for strong coffee lovers.',
                'Price' => 22.99,
                'Category' => 'Coffee',
                'image_url' => 'images/3.png',
                'Stock' => 40
            ],
            [
                'ItemID' => 4,
                'Name' => 'Ethiopia Yirgacheffe Light',
                'Description' => 'Light roast Ethiopian coffee with floral and citrus notes. Wine-like acidity.',
                'Price' => 32.99,
                'Category' => 'Coffee',
                'image_url' => 'images/4.png',
                'Stock' => 25
            ],
            [
                'ItemID' => 5,
                'Name' => 'Brazilian Santos Medium',
                'Description' => 'Medium roast Brazilian coffee with nutty and chocolate flavors. Smooth and balanced.',
                'Price' => 26.99,
                'Category' => 'Coffee',
                'image_url' => 'images/5.jpg',
                'Stock' => 45
            ],
            [
                'ItemID' => 6,
                'Name' => 'Guatemala Antigua Volcanic',
                'Description' => 'Full-bodied Guatemalan coffee with spicy characteristics from volcanic soil.',
                'Price' => 30.99,
                'Category' => 'Coffee',
                'image_url' => 'images/6.jpg',
                'Stock' => 30
            ],
            [
                'ItemID' => 7,
                'Name' => 'Cold Brew Concentrate',
                'Description' => 'Smooth and refreshing cold brew concentrate. Perfect for iced coffee.',
                'Price' => 18.99,
                'Category' => 'Beverages',
                'image_url' => 'images/B1.png',
                'Stock' => 60
            ],
            [
                'ItemID' => 8,
                'Name' => 'Chai Tea Latte Mix',
                'Description' => 'Aromatic chai blend with warming spices for cozy afternoons.',
                'Price' => 16.99,
                'Category' => 'Beverages',
                'image_url' => 'images/B2.png',
                'Stock' => 40
            ],
            [
                'ItemID' => 9,
                'Name' => 'Matcha Green Tea Powder',
                'Description' => 'Premium Japanese matcha powder rich in antioxidants.',
                'Price' => 34.99,
                'Category' => 'Beverages',
                'image_url' => 'images/B3.jpg',
                'Stock' => 20
            ]
        ];

        foreach ($itemsData as $item) {
            Item::create($item);
        }

        $this->command->info('Products and Items seeded successfully!');
    }
}