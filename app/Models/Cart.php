<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Cart extends Model
{
    use HasFactory;

    protected $table = 'carts';

    protected $fillable = [
        'user_id',
        'session_id'
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
            $q->selectRaw('SUM(cart_items.quantity * cart_items.price) as cart_total')
              ->groupBy('cart_items.cart_id')
              ->havingRaw('SUM(cart_items.quantity * cart_items.price) >= ?', [$minAmount]);
        });
    }

    // ========================
    // Relationships
    // ========================

    public function items()
    {
        return $this->hasMany(CartItem::class, 'cart_id', 'id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    public function getTotalAttribute()
    {
        return $this->items->sum(function ($item) {
            return $item->quantity * $item->price;
        });
    }

    public function getItemCountAttribute()
    {
        return $this->items->sum('quantity');
    }
}
