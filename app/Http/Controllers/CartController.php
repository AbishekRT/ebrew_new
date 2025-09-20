<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class CartController extends Controller
{
    // Show cart items
    public function index()
    {
        return view('cart.index'); // create resources/views/cart/index.blade.php
    }

    // Add item to cart (dummy)
    public function add(Request $request, $itemId)
    {
        // Logic to add item to cart
        return redirect()->back()->with('success','Item added to cart!');
    }

    // Remove item
    public function remove($itemId)
    {
        // Logic to remove item
        return redirect()->back()->with('success','Item removed!');
    }
}
