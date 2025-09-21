<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\ProductMySQL;
use App\Models\Order;

class DashboardController extends Controller
{
    public function index()
    {
        // Get current logged-in user
        $user = Auth::user();

        // Example: Fetch last 3 orders of this user
        $orders = Order::where('UserID', $user->id)
                        ->orderBy('OrderDate', 'desc')
                        ->take(3)
                        ->get();

        // Fetch random 3 recommended products from MySQL
        try {
            $recommended = ProductMySQL::inRandomOrder()->take(3)->get();
        } catch (\Exception $e) {
            // If there's any issue, just set empty collection
            $recommended = collect([]);
        }

        return view('dashboard', compact('user', 'orders', 'recommended'));
    }
}
