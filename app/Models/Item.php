<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Item extends Model
{
    use HasFactory;

    protected $table = 'items';
    protected $primaryKey = 'ItemID';
    public $timestamps = false;

    protected $fillable = [
        'Name', 'Description', 'Price', 'TastingNotes', 
        'ShippingAndReturns', 'RoastDates', 'Image'
    ];

    // Relationships
    public function cartItems()
    {
        return $this->hasMany(CartItem::class, 'ItemID', 'ItemID');
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class, 'ItemID', 'ItemID');
    }
}
