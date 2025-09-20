<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class OrderController extends Controller
{
    // Show all orders
    public function index()
    {
        return view('orders.index'); // create resources/views/orders/index.blade.php
    }

    // Show order details
    public function show($id)
    {
        return view('orders.show', ['id'=>$id]); // create resources/views/orders/show.blade.php
    }
}
