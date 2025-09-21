<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Http;

class ProductController extends Controller
{
    // Products list page
    public function index()
    {
        // Call the API
        $response = Http::get(url('/api/products'));

        // If API call fails, fallback to empty array
        if ($response->failed()) {
            $products = [];
        } else {
            $json = $response->json();
            // API returns: ['status' => 'success', 'data' => [...]]
            $products = $json['data'] ?? [];
        }

        return view('products', compact('products'));
    }

    // Single product page
    public function show($id)
    {
        $response = Http::get(url("/api/products/{$id}"));

        if ($response->failed()) {
            abort(404, 'Product not found');
        }

        $json = $response->json();
        $product = $json['data'] ?? null;

        if (!$product) {
            abort(404, 'Product not found');
        }

        return view('product_detail', compact('product'));
    }
}
