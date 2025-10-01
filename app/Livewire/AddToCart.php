<?php

namespace App\Livewire;

use Livewire\Component;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Item;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class AddToCart extends Component
{
    public $item;
    public $itemId;
    public $quantity = 1;
    public $showNotification = false;
    public $notificationMessage = '';
    public $notificationType = 'success';
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
        Log::info('AddToCart: Method called', [
            'item_id' => $this->item->id,
            'item_name' => $this->item->Name,
            'quantity' => $this->quantity,
            'is_auth' => Auth::check()
        ]);

        $this->isAdding = true;

        try {
            // Validate item exists and has required fields
            if (!$this->item || !$this->item->id || !$this->item->Name || $this->item->Price === null) {
                throw new \Exception('Invalid item data: Item ID=' . ($this->item->id ?? 'null') . ', Name=' . ($this->item->Name ?? 'null') . ', Price=' . ($this->item->Price ?? 'null'));
            }
            
            // Validate quantity
            if ($this->quantity < 1) {
                throw new \Exception('Invalid quantity: must be at least 1');
            }

            if (Auth::check()) {
                // Authenticated user - save to database
                Log::info('AddToCart: Authenticated user cart', ['user_id' => Auth::id()]);
                
                // Ensure user exists and is valid
                $user = Auth::user();
                if (!$user || !$user->id) {
                    throw new \Exception('Invalid user authentication state');
                }
                
                $cart = Cart::firstOrCreate(['UserID' => Auth::id()]);
                
                // Validate cart was created/found successfully
                if (!$cart || !$cart->id) {
                    throw new \Exception('Failed to create or find user cart');
                }
                
                Log::info('AddToCart: Cart created/found', ['cart_id' => $cart->id, 'user_id' => Auth::id()]);
                
                // Check if item already exists in cart
                $existingCartItem = CartItem::where('CartID', $cart->id)
                    ->where('ItemID', $this->item->id)
                    ->first();

                if ($existingCartItem) {
                    Log::info('AddToCart: Updating existing item', [
                        'cart_item_id' => $existingCartItem->id,
                        'current_quantity' => $existingCartItem->Quantity,
                        'adding_quantity' => $this->quantity
                    ]);
                    
                    // Update existing cart item quantity
                    $newQuantity = $existingCartItem->Quantity + $this->quantity;
                    $updated = CartItem::where('CartID', $cart->id)
                           ->where('ItemID', $this->item->id)
                           ->update(['Quantity' => $newQuantity]);
                           
                    if (!$updated) {
                        throw new \Exception('Failed to update cart item quantity');
                    }
                } else {
                    Log::info('AddToCart: Creating new cart item', [
                        'cart_id' => $cart->id,
                        'item_id' => $this->item->id,
                        'quantity' => $this->quantity
                    ]);
                    
                    // Validate required data before creation
                    if (!$cart->id || !$this->item->id || !$this->quantity) {
                        throw new \Exception('Invalid data for cart item creation: CartID=' . ($cart->id ?? 'null') . ', ItemID=' . ($this->item->id ?? 'null') . ', Quantity=' . ($this->quantity ?? 'null'));
                    }
                    
                    // Create new cart item with explicit validation
                    $cartItemData = [
                        'CartID' => (int) $cart->id,
                        'ItemID' => (int) $this->item->id,
                        'Quantity' => (int) $this->quantity
                    ];
                    
                    Log::info('AddToCart: Attempting to create cart item', $cartItemData);
                    
                    $cartItem = CartItem::create($cartItemData);
                    
                    if (!$cartItem || !$cartItem->id) {
                        throw new \Exception('CartItem creation failed - no item returned or no ID assigned');
                    }
                    
                    Log::info('AddToCart: Cart item created successfully', [
                        'cart_item_id' => $cartItem->id,
                        'cart_id' => $cartItem->CartID,
                        'item_id' => $cartItem->ItemID,
                        'quantity' => $cartItem->Quantity
                    ]);
                }
            } else {
                // Guest user - save to session
                Log::info('AddToCart: Guest user cart');
                $sessionCart = session()->get('cart', []);
                Log::info('AddToCart: Current session cart', ['cart_count' => count($sessionCart)]);
                
                $itemId = $this->item->id;
                
                if (isset($sessionCart[$itemId])) {
                    $sessionCart[$itemId]['quantity'] += $this->quantity;
                    Log::info('AddToCart: Updated existing session item', [
                        'item_id' => $itemId,
                        'new_quantity' => $sessionCart[$itemId]['quantity']
                    ]);
                } else {
                    $sessionCart[$itemId] = [
                        'item_id' => $itemId,
                        'name' => $this->item->Name,
                        'price' => (float) $this->item->Price,
                        'quantity' => $this->quantity,
                        'image' => $this->item->image_url ?? asset('images/default.png')
                    ];
                    Log::info('AddToCart: Added new session item', [
                        'item_id' => $itemId,
                        'name' => $this->item->Name,
                        'quantity' => $this->quantity
                    ]);
                }
                
                session()->put('cart', $sessionCart);
                Log::info('AddToCart: Session cart updated', ['total_items' => count($sessionCart)]);
            }

            Log::info('AddToCart: Success - dispatching cartUpdated event');
            $this->dispatch('cartUpdated');
            $this->showNotification("{$this->item->Name} added to cart successfully!", 'success');
            
            // Reset quantity to 1 after adding
            $this->quantity = 1;

        } catch (\Exception $e) {
            Log::error('AddToCart: Critical error occurred', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'item_id' => $this->item->id ?? 'unknown',
                'user_id' => Auth::id(),
                'trace' => $e->getTraceAsString()
            ]);
            $this->showNotification('Error adding item to cart: ' . $e->getMessage(), 'error');
        }

        $this->isAdding = false;
    }

    private function showNotification($message, $type = 'success')
    {
        $this->notificationMessage = $message;
        $this->notificationType = $type;
        $this->showNotification = true;
    }

    public function hideNotification()
    {
        $this->showNotification = false;
        $this->notificationMessage = '';
        $this->notificationType = 'success';
    }

    public function render()
    {
        return view('livewire.add-to-cart');
    }
}
