<?php

namespace App\Livewire;

use Livewire\Component;
use App\Models\Cart;
use App\Models\CartItem;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

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
        try {
            // Only log in development/local environments
            if (app()->environment(['local', 'development'])) {
                Log::info('CartCounter: Updating count', ['is_auth' => Auth::check()]);
            }
            
            if (Auth::check()) {
                // Authenticated user - get from database with error handling
                try {
                    $cart = Cart::where('UserID', Auth::id())->first();
                    
                    if ($cart) {
                        $this->cartCount = CartItem::where('CartID', $cart->id)->sum('Quantity') ?? 0;
                    } else {
                        $this->cartCount = 0;
                    }
                } catch (\Exception $e) {
                    // Fallback to session if database fails
                    if (app()->environment(['local', 'development'])) {
                        Log::error('CartCounter: Database error, falling back to session', ['error' => $e->getMessage()]);
                    }
                    $sessionCart = session()->get('cart', []);
                    $this->cartCount = collect($sessionCart)->sum('quantity') ?? 0;
                }
            } else {
                // Guest user - get from session
                $sessionCart = session()->get('cart', []);
                $this->cartCount = collect($sessionCart)->sum('quantity') ?? 0;
                
                if (app()->environment(['local', 'development'])) {
                    Log::info('CartCounter: Guest cart count', [
                        'session_cart' => $sessionCart,
                        'count' => $this->cartCount
                    ]);
                }
            }
            
            if (app()->environment(['local', 'development'])) {
                Log::info('CartCounter: Final count', ['count' => $this->cartCount]);
            }
        } catch (\Exception $e) {
            // Ultimate fallback - set count to 0
            if (app()->environment(['local', 'development', 'staging'])) {
                Log::error('CartCounter: Critical error, setting count to 0', ['error' => $e->getMessage()]);
            }
            $this->cartCount = 0;
        }
    }

    public function render()
    {
        return view('livewire.cart-counter');
    }
}
