<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Order;
use App\Models\OrderItem;

class CheckoutController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function index()
    {
        $user = Auth::user();
        
        // Get user's cart
        $cart = Cart::where('UserID', $user->id)->with('items.item')->first();
        
        if (!$cart || $cart->items->isEmpty()) {
            return redirect()->route('cart.index')->with('error', 'Your cart is empty.');
        }

        return view('checkout.index', compact('cart', 'user'));
    }

    public function process(Request $request)
    {
        $user = Auth::user();
        
        // Get user's cart
        $cart = Cart::where('UserID', $user->id)->with('items.item')->first();
        
        if (!$cart || $cart->items->isEmpty()) {
            return redirect()->route('cart.index')->with('error', 'Your cart is empty.');
        }

        // Create order using raw SQL to avoid any model issues
        $orderData = [
            'UserID' => $user->id,
            'OrderDate' => now(),
            'SubTotal' => $cart->total
        ];
        
        // Insert order directly into database
        $orderId = \DB::table('orders')->insertGetId([
            'UserID' => $user->id,
            'OrderDate' => now(),
            'SubTotal' => $cart->total
        ]);

        // Create a simple order object for the view
        $order = (object)[
            'OrderID' => $orderId,
            'UserID' => $user->id,
            'OrderDate' => now(),
            'SubTotal' => $cart->total
        ];

        // Create order items
        foreach ($cart->items as $cartItem) {
            \DB::table('order_items')->insert([
                'OrderID' => $orderId,
                'ItemID' => $cartItem->ItemID,
                'Quantity' => $cartItem->Quantity
            ]);
        }

        // Clear cart
        $cart->items()->delete();

        return view('checkout.success', compact('user', 'order'));
    }

    public function buyNow($itemId)
    {
        $user = Auth::user();
        
        // Clear existing cart
        $cart = Cart::where('UserID', $user->id)->first();
        if ($cart) {
            $cart->items()->delete();
        } else {
            $cart = Cart::create(['UserID' => $user->id]);
        }

        // Add single item to cart
        CartItem::create([
            'CartID' => $cart->CartID,
            'ItemID' => $itemId,
            'Quantity' => 1
        ]);

        return redirect()->route('checkout.index');
    }
}