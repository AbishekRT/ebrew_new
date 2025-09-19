<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class User extends Model
{
    use HasFactory;

    protected $table = 'users';
    protected $primaryKey = 'UserID';
    public $timestamps = false;

    protected $fillable = [
        'FullName', 'Email', 'Phone', 'DeliveryAddress', 'Password', 'Role'
    ];

    // Relationships
    public function carts()
    {
        return $this->hasMany(Cart::class, 'UserID', 'UserID');
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'UserID', 'UserID');
    }
}
