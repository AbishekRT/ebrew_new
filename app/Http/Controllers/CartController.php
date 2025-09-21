<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class CartController extends Controller
{
    // Show cart items - now using Livewire
    public function index()
    {
        return view('cart'); // renders cart.blade.php with Livewire component
    }
}
