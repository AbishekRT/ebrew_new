<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Item;

class ItemController extends Controller
{
    // Show all items
    public function index()
    {
        $items = Item::all();
        return view('items.index', compact('items'));
    }

    // Show single item
    public function show($ItemID)
    {
        $item = Item::where('ItemID', $ItemID)->firstOrFail();
        return view('items.show', compact('item'));
    }
}