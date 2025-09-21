<?php

namespace App\Models;

use Jenssegers\Mongodb\Eloquent\Model as Eloquent;

class Cart extends Eloquent
{
    protected $connection = 'mongodb';
    protected $collection = 'carts';

    protected $fillable = ['user_id'];

    public function items()
    {
        return $this->hasMany(CartItem::class, 'cart_id', '_id');
    }
}
