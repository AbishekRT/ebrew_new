<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class ItemController extends Controller
{
    // Show all items
    public function index()
    {
        return view('items.index'); // create resources/views/items/index.blade.php
    }

    // Show single item
    public function show($id)
    {
        return view('items.show', ['id'=>$id]); // create resources/views/items/show.blade.php
    }
}
