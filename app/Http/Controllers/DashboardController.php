<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Product;
use App\Models\Order;

class DashboardController extends Controller
{
    public function index()
    {
        // Get current logged-in user
        $user = Auth::user();

        // Example: Fetch last 3 orders of this user
        $orders = Order::where('user_id', $user->id)
                        ->latest()
                        ->take(3)
                        ->get();

        // Example: Fetch random 3 recommended products
        $recommended = Product::inRandomOrder()->take(3)->get();

        return view('dashboard', compact('user', 'orders', 'recommended'));
    }
}
