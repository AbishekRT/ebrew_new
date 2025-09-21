<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model as Eloquent;

class Product extends Eloquent
{
    protected $connection = 'mongodb';
    protected $collection = 'products';

    protected $fillable = [
        'name', 'price', 'image', 'description',
        'tastingNotes', 'shippingAndReturns', 'roastDates'
    ];
}