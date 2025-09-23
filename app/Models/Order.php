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

        protected $fillable = [
        'UserID',
        'OrderDate', 
        'SubTotal'
    ];

    /**
     * Get the attributes that should be cast.
     */
    protected function casts(): array
    {
        return [
            'OrderDate' => 'datetime',
            'SubTotal' => 'decimal:2',
        ];
    }

    // ========================
    // Query Scopes
    // ========================
    
    /**
     * Scope to filter orders by date range
     */
    public function scopeDateRange($query, $startDate, $endDate = null)
    {
        $query->where('OrderDate', '>=', $startDate);
        if ($endDate) {
            $query->where('OrderDate', '<=', $endDate);
        }
        return $query;
    }

    /**
     * Scope to get orders above certain amount
     */
    public function scopeHighValue($query, $minAmount = 5000)
    {
        return $query->where('SubTotal', '>=', $minAmount);
    }

    /**
     * Scope to get recent orders
     */
    public function scopeRecent($query, $days = 30)
    {
        return $query->where('OrderDate', '>=', now()->subDays($days));
    }

    /**
     * Scope to get orders with specific payment status
     */
    public function scopeByPaymentStatus($query, $status)
    {
        return $query->whereHas('payments', function ($q) use ($status) {
            $q->where('PaymentStatus', $status);
        });
    }

    /**
     * Scope to get complete orders (with items and payments)
     */
    public function scopeComplete($query)
    {
        return $query->with(['user', 'orderItems.item', 'payments']);
    }

    // ========================
    // Mutators & Accessors
    // ========================
    
    /**
     * Accessor: Get formatted subtotal
     */
    public function getFormattedSubTotalAttribute()
    {
        return 'LKR ' . number_format($this->SubTotal, 2);
    }

    /**
     * Accessor: Get order status based on payments
     */
    public function getStatusAttribute()
    {
        if ($this->payments->isEmpty()) {
            return 'pending';
        }
        
        $latestPayment = $this->payments->sortByDesc('PaymentDate')->first();
        return strtolower($latestPayment->PaymentStatus);
    }

    /**
     * Accessor: Get total items count
     */
    public function getTotalItemsAttribute()
    {
        return $this->orderItems->sum('Quantity');
    }

    /**
     * Accessor: Check if order is recent
     */
    public function getIsRecentAttribute()
    {
        return $this->OrderDate >= now()->subDays(7);
    }

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class, 'UserID', 'id');
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class, 'OrderID', 'OrderID')->with('item');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'OrderID', 'OrderID');
    }

    /**
     * Get reviews for this order (polymorphic)
     */
    public function reviews()
    {
        return $this->morphMany(Review::class, 'reviewable');
    }

    /**
     * Get items in this order (many-to-many with pivot data)
     */
    public function items()
    {
        return $this->belongsToMany(Item::class, 'order_items', 'OrderID', 'ItemID')
                    ->withPivot('Quantity');
    }

    /**
     * Get the latest payment
     */
    public function latestPayment()
    {
        return $this->hasOne(Payment::class, 'OrderID', 'OrderID')
                    ->latestOfMany('PaymentDate');
    }

    /**
     * Get successful payments only
     */
    public function successfulPayments()
    {
        return $this->hasMany(Payment::class, 'OrderID', 'OrderID')
                    ->where('PaymentStatus', 'paid');
    }
}
