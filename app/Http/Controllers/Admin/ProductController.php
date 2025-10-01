<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Item;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProductController extends Controller
{
    /**
     * Display a listing of the products with add/edit interface
     */
    public function index()
    {
        $products = Item::orderBy('id', 'desc')->get();
        
        return view('admin.products.index', compact('products'));
    }

    /**
     * Store a newly created product in storage
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'required|string',
            'price' => 'required|numeric|min:0',
            'tasting_notes' => 'nullable|string',
            'shipping_returns' => 'nullable|string',
            'roast_date' => 'nullable|date',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048'
        ]);

        $imagePath = null;
        
        // Handle image upload
        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('products', 'public');
        }

        Item::create([
            'Name' => $validated['name'],
            'Description' => $validated['description'],
            'Price' => $validated['price'],
            'TastingNotes' => $validated['tasting_notes'],
            'ShippingAndReturns' => $validated['shipping_returns'],
            'RoastDates' => $validated['roast_date'],
            'Image' => $imagePath ? '/storage/' . $imagePath : null,
        ]);

        return redirect()->route('admin.products.index')
            ->with('success', 'Product created successfully.');
    }

    /**
     * Show the form for editing the specified product
     */
    public function edit($id)
    {
        $product = Item::findOrFail($id);
        return view('admin.products.edit', compact('product'));
    }

    /**
     * Update the specified product in storage
     */
    public function update(Request $request, $id)
    {
        $product = Item::findOrFail($id);
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'required|string',
            'price' => 'required|numeric|min:0',
            'tasting_notes' => 'nullable|string',
            'shipping_returns' => 'nullable|string',
            'roast_date' => 'nullable|date',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048'
        ]);

        // Handle image upload
        if ($request->hasFile('image')) {
            // Delete old image if exists
            if ($product->Image) {
                $oldImagePath = str_replace('/storage/', '', $product->Image);
                Storage::disk('public')->delete($oldImagePath);
            }
            
            $imagePath = $request->file('image')->store('products', 'public');
            $validated['image_path'] = '/storage/' . $imagePath;
        }

        $product->update([
            'Name' => $validated['name'],
            'Description' => $validated['description'],
            'Price' => $validated['price'],
            'TastingNotes' => $validated['tasting_notes'],
            'ShippingAndReturns' => $validated['shipping_returns'],
            'RoastDates' => $validated['roast_date'],
            'Image' => $validated['image_path'] ?? $product->Image,
        ]);

        return redirect()->route('admin.products.index')
            ->with('success', 'Product updated successfully.');
    }

    /**
     * Remove the specified product from storage
     */
    public function destroy($id)
    {
        $product = Item::findOrFail($id);
        // Delete image file if exists
        if ($product->Image) {
            $imagePath = str_replace('/storage/', '', $product->Image);
            Storage::disk('public')->delete($imagePath);
        }

        $product->delete();

        return redirect()->route('admin.products.index')
            ->with('success', 'Product deleted successfully.');
    }
}