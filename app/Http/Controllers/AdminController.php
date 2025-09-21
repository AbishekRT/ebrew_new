<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Item;
use App\Models\Order;
use App\Models\User;

class AdminController extends Controller
{
    public function index()
    {
        try {
            // Get statistics using correct table/column names
            $totalProducts = Item::count(); // Using items table instead of products
            $totalOrders   = Order::count();
            $totalSales    = Order::sum('SubTotal'); // Using SubTotal column instead of total_price
            
            // Get top selling item (simplified version since we don't have order_items relationship set up properly)
            $topProduct = Item::first(); // For now, just get the first item
            
            return view('admin.dashboard', compact(
                'totalProducts',
                'totalOrders',
                'totalSales',
                'topProduct'
            ));
        } catch (\Exception $e) {
            // Handle any database errors gracefully
            return view('admin.dashboard', [
                'totalProducts' => 0,
                'totalOrders' => 0,
                'totalSales' => 0,
                'topProduct' => null,
                'error' => 'Unable to load dashboard statistics: ' . $e->getMessage()
            ]);
        }
    }
}
