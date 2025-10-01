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
        $orderId = DB::table('orders')->insertGetId([
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
            DB::table('order_items')->insert([
                'OrderID' => $orderId,
                'ItemID' => $cartItem->ItemID,
                'Quantity' => $cartItem->Quantity,
                'Price' => $cartItem->item->Price // Store price at time of purchase
            ]);
        }

        // Clear cart
        $cart->items()->delete();

        return view('checkout.success', compact('user', 'order'));
    }

    public function buyNow($itemId)
    {
        // Check if user is authenticated
        if (!Auth::check()) {
            return redirect()->route('login')->with('message', 'Please login to purchase items.');
        }
        
        $user = Auth::user();
        
        try {
            // Validate item exists
            $item = \App\Models\Item::find($itemId);
            if (!$item) {
                return redirect()->back()->with('error', 'Product not found.');
            }
            
            // Get or create cart for user
            $cart = Cart::firstOrCreate(['UserID' => $user->id]);
            
            // Clear existing cart items
            if ($cart) {
                $cart->items()->delete();
                \Log::info('BuyNow: Cleared existing cart items', ['cart_id' => $cart->id]);
            }
            
            // Ensure we have a valid cart ID
            if (!$cart || !$cart->id) {
                \Log::error('BuyNow: Cart creation failed', ['user_id' => $user->id]);
                return redirect()->back()->with('error', 'Unable to create cart. Please try again.');
            }

            // Add single item to cart
            $cartItem = CartItem::create([
                'CartID' => $cart->id,
                'ItemID' => $itemId,
                'Quantity' => 1
            ]);
            
            if (!$cartItem) {
                \Log::error('BuyNow: CartItem creation failed', [
                    'cart_id' => $cart->id,
                    'item_id' => $itemId
                ]);
                return redirect()->back()->with('error', 'Unable to add item to cart. Please try again.');
            }
            
            \Log::info('BuyNow: Item added successfully', [
                'cart_id' => $cart->id,
                'item_id' => $itemId,
                'cart_item_id' => $cartItem->id
            ]);

            return redirect()->route('checkout.index');
            
        } catch (\Exception $e) {
            \Log::error('BuyNow: Exception occurred', [
                'message' => $e->getMessage(),
                'user_id' => $user->id,
                'item_id' => $itemId,
                'trace' => $e->getTraceAsString()
            ]);
            
            return redirect()->back()->with('error', 'An error occurred while processing your request. Please try again.');
        }
    }
}
