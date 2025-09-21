<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product; // MongoDB Model
use Illuminate\Http\Request;

class ProductApiController extends Controller
{
    // GET /api/products
    public function index()
    {
        $products = Product::all();
        return response()->json([
            'status' => 'success',
            'data' => $products
        ]);
    }

    // GET /api/products/{id}
    public function show($id)
    {
        $product = Product::find($id);

        if (!$product) {
            return response()->json([
                'status' => 'error',
                'message' => 'Product not found'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $product
        ]);
    }

    // POST /api/products (protected)
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'price' => 'required|numeric',
            'image' => 'required|string',
            'description' => 'nullable|string'
        ]);

        $product = Product::create($validated);

        return response()->json([
            'status' => 'success',
            'data' => $product
        ], 201);
    }

    // PUT /api/products/{id} (protected)
    public function update(Request $request, $id)
    {
        $product = Product::find($id);

        if (!$product) {
            return response()->json([
                'status' => 'error',
                'message' => 'Product not found'
            ], 404);
        }

        $product->update($request->all());

        return response()->json([
            'status' => 'success',
            'data' => $product
        ]);
    }

    // DELETE /api/products/{id} (protected)
    public function destroy($id)
    {
        $product = Product::find($id);

        if (!$product) {
            return response()->json([
                'status' => 'error',
                'message' => 'Product not found'
            ], 404);
        }

        $product->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Product deleted successfully'
        ]);
    }
}
