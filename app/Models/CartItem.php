<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CartItem extends Model
{
    use HasFactory;

    protected $table = 'cart_items';
    public $timestamps = false;
    protected $primaryKey = null; // composite key
    public $incrementing = false;

    protected $fillable = ['CartID', 'ItemID', 'Quantity'];

    // Relationships
    public function cart()
    {
        return $this->belongsTo(Cart::class, 'CartID', 'CartID');
    }

    public function item()
    {
        return $this->belongsTo(Item::class, 'ItemID', 'ItemID');
    }
}
