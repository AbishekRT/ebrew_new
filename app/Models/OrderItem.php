<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    use HasFactory;

    protected $table = 'order_items';
    public $timestamps = false;
    protected $primaryKey = null; // composite key
    public $incrementing = false;

    protected $fillable = ['OrderID', 'ItemID', 'Quantity', 'Price'];

    // Relationships
    public function order()
    {
        return $this->belongsTo(Order::class, 'OrderID', 'id');
    }

    public function item()
    {
        return $this->belongsTo(Item::class, 'ItemID', 'id');
    }
}
