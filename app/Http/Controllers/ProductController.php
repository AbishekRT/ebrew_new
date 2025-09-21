<?php

namespace App\Http\Controllers;

use App\Models\Item;

class ProductController extends Controller
{
    // Products list page
    public function index()
    {
        // Get products directly from database
        $products = Item::all();

        return view('products', compact('products'));
    }

    // Single product page
    public function show($id)
    {
        $product = Item::find($id);

        if (!$product) {
            abort(404, 'Product not found');
        }

        return view('product_detail', compact('product'));
    }
}
