<?php

namespace App\Models;

use Jenssegers\Mongodb\Eloquent\Model as Eloquent;

class CartItem extends Eloquent
{
    protected $connection = 'mongodb';
    protected $collection = 'cart_items';

    protected $fillable = ['cart_id', 'product_id', 'quantity'];

    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id', '_id');
    }
}
