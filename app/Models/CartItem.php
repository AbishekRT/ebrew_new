<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CartItem extends Model
{
    use HasFactory;

    protected $table = 'cart_items';
    protected $primaryKey = 'id'; // Standard Laravel primary key
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
        return $this->belongsTo(Cart::class, 'CartID', 'id');
    }

    public function item()
    {
        return $this->belongsTo(Item::class, 'ItemID', 'id');
    }

    public function getTotalAttribute()
    {
        // Ensure item relationship exists and has valid Price
        if (!$this->item || !$this->item->Price) {
            \Log::warning('CartItem getTotalAttribute: Invalid item or price', [
                'cart_item_id' => $this->id,
                'item_id' => $this->ItemID,
                'has_item' => $this->item !== null,
                'item_price' => $this->item ? $this->item->Price : null
            ]);
            return 0;
        }
        
        return $this->Quantity * (float) $this->item->Price;
    }
}
