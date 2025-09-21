<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CartItem extends Model
{
    use HasFactory;

    protected $table = 'cart_items';
    
    protected $fillable = [
        'cart_id',
        'item_id',
        'quantity',
        'price'
    ];

    public function cart()
    {
        return $this->belongsTo(Cart::class, 'cart_id', 'id');
    }

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id', 'ItemID');
    }

    public function getTotalAttribute()
    {
        return $this->quantity * $this->price;
    }
}
