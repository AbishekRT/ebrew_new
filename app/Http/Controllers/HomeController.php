<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Item;

class HomeController extends Controller
{
    public function index()
    {
        // Get featured/best selling products from database
        // You can modify this query based on your business logic:
        // - Most recent: ->latest()->take(8)
        // - Random selection: ->inRandomOrder()->take(8)
        // - Best sellers: ->orderBy('sales_count', 'desc')->take(8)
        // - Specific featured products: ->where('is_featured', true)->take(8)
        
        $featuredProducts = Item::take(8)->get(); // Simple approach for now
        
        return view('home', compact('featuredProducts'));
    }
}