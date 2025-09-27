<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CartItem extends Model
{
    use HasFactory;

    protected $table = 'cart_items';
    protected $primaryKey = 'CartItemID'; // Use CartItemID as primary key
    public $incrementing = true;
    protected $keyType = 'int';
    public $timestamps = false;

    protected $fillable = [
        'CartID',
        'ItemID', 
        'Quantity'
    ];

    public function cart()
    {
        return $this->belongsTo(Cart::class, 'CartID', 'CartID');
    }

    public function item()
    {
        return $this->belongsTo(Item::class, 'ItemID', 'id');
    }

    public function getTotalAttribute()
    {
        return $this->Quantity * $this->item->Price;
    }
}
