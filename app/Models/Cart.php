<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Cart extends Model
{
    use HasFactory;

    protected $table = 'carts';
    protected $primaryKey = 'CartID';
    public $timestamps = false;

    protected $fillable = ['UserID'];

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class, 'UserID', 'UserID');
    }

    public function cartItems()
    {
        return $this->hasMany(CartItem::class, 'CartID', 'CartID')->with('item');
    }
}
