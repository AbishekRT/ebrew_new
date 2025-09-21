<?php

namespace App\Livewire;

use Livewire\Component;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Item;
use Illuminate\Support\Facades\Auth;

class AddToCart extends Component
{
    public $item;
    public $itemId;
    public $quantity = 1;
    public $showNotification = false;
    public $notificationMessage = '';
    public $isAdding = false;
    public $debugMessage = 'Component loaded!';

    public function mount($itemId)
    {
        $this->itemId = $itemId;
        $this->item = Item::findOrFail($itemId);
        $this->debugMessage = 'Item loaded: ' . $this->item->Name;
    }

    public function incrementQuantity()
    {
        $this->quantity++;
    }

    public function decrementQuantity()
    {
        if ($this->quantity > 1) {
            $this->quantity--;
        }
    }

    public function addToCart()
    {
        \Log::info('AddToCart: Method called', [
            'item_id' => $this->item->ItemID,
            'quantity' => $this->quantity,
            'is_auth' => Auth::check()
        ]);

        $this->isAdding = true;

        try {
            if (Auth::check()) {
                // Authenticated user - save to database
                \Log::info('AddToCart: Authenticated user cart');
                $cart = Cart::firstOrCreate(['user_id' => Auth::id()]);
                \Log::info('AddToCart: Cart created/found', ['cart_id' => $cart->id]);
                
                $existingCartItem = CartItem::where('cart_id', $cart->id)
                    ->where('item_id', $this->item->ItemID)
                    ->first();

                if ($existingCartItem) {
                    \Log::info('AddToCart: Updating existing item');
                    $existingCartItem->update([
                        'quantity' => $existingCartItem->quantity + $this->quantity
                    ]);
                } else {
                    \Log::info('AddToCart: Creating new cart item');
                    CartItem::create([
                        'cart_id' => $cart->id,
                        'item_id' => $this->item->ItemID,
                        'quantity' => $this->quantity,
                        'price' => $this->item->Price
                    ]);
                }
            } else {
                // Guest user - save to session
                \Log::info('AddToCart: Guest user cart');
                $sessionCart = session()->get('cart', []);
                \Log::info('AddToCart: Current session cart', $sessionCart);
                
                $itemId = $this->item->ItemID;
                
                if (isset($sessionCart[$itemId])) {
                    $sessionCart[$itemId]['quantity'] += $this->quantity;
                } else {
                    $sessionCart[$itemId] = [
                        'item_id' => $itemId,
                        'name' => $this->item->Name,
                        'price' => $this->item->Price,
                        'quantity' => $this->quantity,
                        'image' => $this->item->image_url
                    ];
                }
                
                session()->put('cart', $sessionCart);
                \Log::info('AddToCart: Updated session cart', $sessionCart);
            }

            \Log::info('AddToCart: Dispatching cartUpdated event');
            $this->dispatch('cartUpdated');
            $this->showNotification("{$this->item->Name} added to cart!", 'success');
            
            // Reset quantity to 1 after adding
            $this->quantity = 1;

        } catch (\Exception $e) {
            \Log::error('AddToCart: Error', ['message' => $e->getMessage()]);
            $this->showNotification('Error adding item to cart. Please try again.', 'error');
        }

        $this->isAdding = false;
    }

    private function showNotification($message, $type = 'success')
    {
        $this->notificationMessage = $message;
        $this->showNotification = true;
        
        // Auto-hide after 4 seconds
        $this->dispatch('startNotificationTimer');
    }

    public function hideNotification()
    {
        $this->showNotification = false;
        $this->notificationMessage = '';
    }

    public function render()
    {
        return view('livewire.add-to-cart');
    }
}
