<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    use HasFactory;

    protected $table = 'payments';
    protected $primaryKey = 'PaymentID';
    public $timestamps = false;

    protected $fillable = ['PaymentDate', 'PaymentStatus', 'PaymentAmount', 'OrderID'];

    // Relationships
    public function order()
    {
        return $this->belongsTo(Order::class, 'OrderID', 'OrderID');
    }

    // Optional helper: check if payment is complete
    public function getIsPaidAttribute()
    {
        return strtolower($this->PaymentStatus) === 'paid';
    }
}
