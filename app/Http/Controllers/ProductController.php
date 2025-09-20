<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProductController extends Controller
{
    public function index()
    {
        $products = DB::table('items')->limit(8)->get();
        return view('products', compact('products'));
    }

    public function show($id)
    {
        $product = DB::table('items')->where('ItemID', $id)->first();
        return view('product_details', compact('product'));
    }
}
