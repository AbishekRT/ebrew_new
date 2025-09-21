<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Item; // MySQL Model
use Illuminate\Http\Request;

class ProductApiController extends Controller
{
    // GET /api/products
    public function index()
    {
        $products = Item::all();
        return response()->json([
            'status' => 'success',
            'data' => $products
        ]);
    }

    // GET /api/products/{id}
    public function show($id)
    {
        $product = Item::find($id);

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
            'Name' => 'required|string|max:255',
            'Price' => 'required|numeric',
            'Image' => 'required|string',
            'Description' => 'nullable|string',
            'TastingNotes' => 'nullable|string',
            'ShippingAndReturns' => 'nullable|string',
            'RoastDates' => 'nullable|string'
        ]);

        $product = Item::create($validated);

        return response()->json([
            'status' => 'success',
            'data' => $product
        ], 201);
    }

    // PUT /api/products/{id} (protected)
    public function update(Request $request, $id)
    {
        $product = Item::find($id);

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
        $product = Item::find($id);

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
