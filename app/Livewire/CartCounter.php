<?php

namespace App\Livewire;

use Livewire\Component;
use App\Models\Cart;
use App\Models\CartItem;
use Illuminate\Support\Facades\Auth;

class CartCounter extends Component
{
    public $cartCount = 0;

    protected $listeners = ['cartUpdated' => 'updateCount'];

    public function mount()
    {
        $this->updateCount();
    }

    public function updateCount()
    {
        \Log::info('CartCounter: Updating count', ['is_auth' => Auth::check()]);
        
        if (Auth::check()) {
            // Authenticated user - get from database
            $cart = Cart::where('UserID', Auth::id())->first();
            
            if ($cart) {
                $this->cartCount = CartItem::where('CartID', $cart->CartID)->sum('Quantity');
            } else {
                $this->cartCount = 0;
            }
        } else {
            // Guest user - get from session
            $sessionCart = session()->get('cart', []);
            $this->cartCount = collect($sessionCart)->sum('quantity');
            \Log::info('CartCounter: Guest cart count', [
                'session_cart' => $sessionCart,
                'count' => $this->cartCount
            ]);
        }
        
        \Log::info('CartCounter: Final count', ['count' => $this->cartCount]);
    }

    public function render()
    {
        return view('livewire.cart-counter');
    }
}
