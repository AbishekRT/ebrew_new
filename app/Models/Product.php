<?php

namespace App\Models;

use Jenssegers\Mongodb\Eloquent\Model;

class Product extends Model
{
    protected $connection = 'mongodb'; // matches database.php
    protected $collection = 'products'; // your MongoDB collection name

    protected $fillable = [
        'name', 'price', 'image', 'description',
        'tastingNotes', 'shippingAndReturns', 'roastDates'
    ];
}
