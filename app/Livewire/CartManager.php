<?php

namespace App\Livewire;

use Livewire\Component;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Item;
use Illuminate\Support\Facades\Auth;

class CartManager extends Component
{
    public $cartItems = [];
    public $cartTotal = 0;
    public $cartCount = 0;
    public $showNotification = false;
    public $notificationMessage = '';

    protected $listeners = ['cartUpdated' => 'loadCart'];

    public function mount()
    {
        $this->loadCart();
    }

    public function loadCart()
    {
        if (Auth::check()) {
            // Authenticated user - load from database
            $cart = Cart::firstOrCreate(['UserID' => Auth::id()]);
            
            $this->cartItems = CartItem::where('CartID', $cart->id)
                ->with('item')
                ->get()
                ->map(function ($cartItem) {
                    return [
                        'id' => $cartItem->ItemID, // Use ItemID as identifier for database operations
                        'cart_id' => $cartItem->CartID,
                        'item_id' => $cartItem->ItemID,
                        'quantity' => $cartItem->Quantity,
                        'item' => [
                            'id' => $cartItem->item->id, // Use item's actual primary key
                            'Name' => $cartItem->item->Name,
                            'Price' => $cartItem->item->Price,
                            'image_url' => $cartItem->item->image_url
                        ]
                    ];
                })
                ->toArray();
                
            $this->cartTotal = collect($this->cartItems)->sum(function ($item) {
                return ($item['item']['Price'] ?? 0) * ($item['quantity'] ?? 0);
            });
            
            $this->cartCount = collect($this->cartItems)->sum('quantity');
        } else {
            // Guest user - load from session
            $sessionCart = session()->get('cart', []);
            
            $this->cartItems = collect($sessionCart)->map(function ($item, $itemId) {
                return [
                    'id' => 'session_' . $itemId,
                    'item_id' => $item['item_id'],
                    'quantity' => $item['quantity'],
                    'item' => [
                        'id' => $item['item_id'], // Use consistent field naming
                        'Name' => $item['name'],
                        'Price' => $item['price'],
                        'image_url' => $item['image']
                    ]
                ];
            })->values()->toArray();
            
            $this->cartTotal = collect($this->cartItems)->sum(function ($item) {
                return ($item['item']['Price'] ?? 0) * ($item['quantity'] ?? 0);
            });
            
            $this->cartCount = collect($this->cartItems)->sum('quantity');
        }
    }

    public function updateQuantity($cartItemId, $quantity)
    {
        if ($quantity <= 0) {
            $this->removeFromCart($cartItemId);
            return;
        }

        // Update local state immediately for responsive UI
        foreach ($this->cartItems as &$item) {
            if ($item['id'] == $cartItemId) {
                $item['quantity'] = $quantity;
                break;
            }
        }
        
        // Recalculate totals immediately
        $this->cartTotal = collect($this->cartItems)->sum(function ($item) {
            return ($item['item']['Price'] ?? 0) * ($item['quantity'] ?? 0);
        });
        $this->cartCount = collect($this->cartItems)->sum('quantity');

        if (Auth::check()) {
            // Authenticated user - update database
            $cart = Cart::firstOrCreate(['UserID' => Auth::id()]);
            
            // Use direct query update for composite key table
            $updated = CartItem::where('CartID', $cart->id)
                ->where('ItemID', $cartItemId)
                ->update(['Quantity' => $quantity]);
            
            if (!$updated) {
                // If database update failed, reload from database
                $this->loadCart();
                $this->showNotification('Item not found in cart', 'error');
                return;
            }
        } else {
            // Guest user - update session
            $sessionCart = session()->get('cart', []);
            $sessionItemId = str_replace('session_', '', $cartItemId);
            
            if (isset($sessionCart[$sessionItemId])) {
                $sessionCart[$sessionItemId]['quantity'] = $quantity;
                session()->put('cart', $sessionCart);
            }
        }
        
        // Dispatch event to update other components
        $this->dispatch('cartUpdated');
        
        // Show success message
        $this->showNotification('Cart updated successfully!', 'success');
    }

    public function removeFromCart($cartItemId)
    {
        if (Auth::check()) {
            // Authenticated user - remove from database
            $cart = Cart::firstOrCreate(['UserID' => Auth::id()]);
            
            // Get item name before deletion for notification
            $cartItem = CartItem::where('CartID', $cart->id)
                ->where('ItemID', $cartItemId)
                ->with('item')
                ->first();
            
            if ($cartItem) {
                $itemName = $cartItem->item->Name ?? 'Item';
                
                // Use direct query delete for composite key table
                CartItem::where('CartID', $cart->id)
                    ->where('ItemID', $cartItemId)
                    ->delete();
                    
                $this->showNotification("$itemName removed from cart", 'success');
            }
        } else {
            // Guest user - remove from session
            $sessionCart = session()->get('cart', []);
            $sessionItemId = str_replace('session_', '', $cartItemId);
            
            if (isset($sessionCart[$sessionItemId])) {
                $itemName = $sessionCart[$sessionItemId]['name'] ?? 'Item';
                unset($sessionCart[$sessionItemId]);
                session()->put('cart', $sessionCart);
                $this->showNotification("$itemName removed from cart", 'success');
            }
        }
        
        $this->loadCart();
        $this->dispatch('cartUpdated');
    }

    public function addToCart($itemId, $quantity = 1)
    {
        $item = Item::find($itemId);
        if (!$item) {
            $this->showNotification('Product not found', 'error');
            return;
        }

        if (Auth::check()) {
            // Authenticated user - save to database
            $cart = Cart::firstOrCreate(['UserID' => Auth::id()]);
            
            $existingCartItem = CartItem::where('CartID', $cart->id)
                ->where('ItemID', $itemId)
                ->first();

            if ($existingCartItem) {
                $existingCartItem->update(['Quantity' => $existingCartItem->Quantity + $quantity]);
            } else {
                CartItem::create([
                    'CartID' => $cart->id,
                    'ItemID' => $itemId,
                    'Quantity' => $quantity
                ]);
            }
        } else {
            // Guest user - save to session
            $sessionCart = session()->get('cart', []);
            
            if (isset($sessionCart[$itemId])) {
                $sessionCart[$itemId]['quantity'] += $quantity;
            } else {
                $sessionCart[$itemId] = [
                    'item_id' => $itemId,
                    'name' => $item->Name,
                    'price' => $item->Price,
                    'quantity' => $quantity,
                    'image' => $item->image_url
                ];
            }
            
            session()->put('cart', $sessionCart);
        }

        $this->loadCart();
        $this->dispatch('cartUpdated');
        $this->showNotification("{$item->Name} added to cart!", 'success');
    }

    public function clearCart()
    {
        if (Auth::check()) {
            // Authenticated user - clear database cart
            $cart = Cart::where('UserID', Auth::id())->first();
            if ($cart) {
                CartItem::where('CartID', $cart->id)->delete();
            }
        } else {
            // Guest user - clear session cart
            session()->forget('cart');
        }
        
        $this->loadCart();
        $this->dispatch('cartUpdated');
        $this->showNotification('Cart cleared successfully!', 'success');
    }

    private function showNotification($message, $type = 'success')
    {
        $this->notificationMessage = $message;
        $this->showNotification = true;
        
        // Auto-hide notification after 3 seconds
        $this->dispatch('hideNotification');
    }

    public function hideNotification()
    {
        $this->showNotification = false;
    }

    public function render()
    {
        return view('livewire.cart-manager');
    }
}
