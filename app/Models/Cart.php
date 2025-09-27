<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Cart extends Model
{
    use HasFactory;

    protected $table = 'carts';
    protected $primaryKey = 'id'; // Standard Laravel primary key
    public $timestamps = false;

    protected $fillable = [
        'UserID'
    ];

    // ========================
    // Query Scopes
    // ========================
    
    /**
     * Scope to get carts with items
     */
    public function scopeWithItems($query)
    {
        return $query->with(['items.item']);
    }

    /**
     * Scope to get active carts (with items)
     */
    public function scopeActive($query)
    {
        return $query->whereHas('items');
    }

    /**
     * Scope to get carts above certain value
     */
    public function scopeHighValue($query, $minAmount = 3000)
    {
        return $query->whereHas('items', function ($q) use ($minAmount) {
            $q->selectRaw('SUM(cart_items.Quantity * items.Price) as cart_total')
              ->join('items', 'cart_items.ItemID', '=', 'items.ItemID')
              ->groupBy('cart_items.CartID')
              ->havingRaw('SUM(cart_items.Quantity * items.Price) >= ?', [$minAmount]);
        });
    }

    // ========================
    // Relationships
    // ========================

    public function items()
    {
        return $this->hasMany(CartItem::class, 'CartID', 'id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'UserID', 'id');
    }

    public function getTotalAttribute()
    {
        return $this->items->sum(function ($item) {
            return $item->Quantity * $item->item->Price;
        });
    }

    public function getItemCountAttribute()
    {
        return $this->items->sum('Quantity');
    }
}
