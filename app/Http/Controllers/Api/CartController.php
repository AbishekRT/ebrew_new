<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Product;
use Illuminate\Http\Request;

class CartController extends Controller
{
    // Get current user's cart with product details
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        $cart = Cart::firstOrCreate(['user_id' => $userId]);
        $cart->load('items.product');

        // Format cart for frontend
        $items = $cart->items->map(function($item) {
            return [
                'product_id' => $item->product->_id ?? $item->product_id,
                'name'       => $item->product->name ?? 'Unnamed Product',
                'price'      => $item->product->price ?? 0,
                'image'      => asset($item->product->image ?? 'images/default.png'),
                'quantity'   => $item->quantity,
            ];
        });

        return response()->json([
            'cart_id' => $cart->_id,
            'items'   => $items,
        ]);
    }

    // Add item to cart
    public function add(Request $request)
    {
        $userId = $request->user()->id;
        $productId = $request->input('product_id');
        $quantity = max(1, intval($request->input('quantity', 1)));

        $cart = Cart::firstOrCreate(['user_id' => $userId]);

        $cartItem = CartItem::where('cart_id', $cart->_id)
            ->where('product_id', $productId)
            ->first();

        if ($cartItem) {
            $cartItem->quantity += $quantity;
            $cartItem->save();
        } else {
            CartItem::create([
                'cart_id' => $cart->_id,
                'product_id' => $productId,
                'quantity' => $quantity
            ]);
        }

        return response()->json(['message' => 'Added to cart successfully']);
    }

    // Update quantity (increment/decrement)
    public function update(Request $request)
    {
        $userId = $request->user()->id;
        $cart = Cart::where('user_id', $userId)->firstOrFail();

        $productId = $request->input('product_id');
        $action = $request->input('action');

        $cartItem = CartItem::where('cart_id', $cart->_id)
            ->where('product_id', $productId)
            ->firstOrFail();

        if ($action === 'increment') {
            $cartItem->quantity += 1;
        } elseif ($action === 'decrement') {
            $cartItem->quantity = max(1, $cartItem->quantity - 1);
        }

        $cartItem->save();

        return response()->json(['message' => 'Cart updated successfully']);
    }

    // Remove item from cart
    public function remove(Request $request)
    {
        $userId = $request->user()->id;
        $cart = Cart::where('user_id', $userId)->firstOrFail();

        $productId = $request->input('product_id');

        CartItem::where('cart_id', $cart->_id)
            ->where('product_id', $productId)
            ->delete();

        return response()->json(['message' => 'Item removed successfully']);
    }
}
