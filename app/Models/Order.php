<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $table = 'orders';
    protected $primaryKey = 'OrderID';
    public $timestamps = false;

    protected $fillable = ['OrderDate', 'SubTotal', 'UserID'];

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class, 'UserID', 'UserID');
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class, 'OrderID', 'OrderID')->with('item');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'OrderID', 'OrderID');
    }
}
