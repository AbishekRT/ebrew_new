<?php

namespace App\Models;

use App\Collections\ItemCollection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Item extends Model
{
    use HasFactory;

    protected $table = 'items';
    protected $primaryKey = 'ItemID'; // Use ItemID as primary key
    public $timestamps = false;

    protected $fillable = [
        'Name',
        'Description',
        'Price',
        'TastingNotes',
        'ShippingAndReturns',
        'RoastDates',
        'Image'
    ];

    // ========================
    // Query Scopes
    // ========================
    
    /**
     * Scope to filter items by price range
     */
    public function scopePriceRange($query, $minPrice = null, $maxPrice = null)
    {
        if ($minPrice) {
            $query->where('Price', '>=', $minPrice);
        }
        if ($maxPrice) {
            $query->where('Price', '<=', $maxPrice);
        }
        return $query;
    }

    /**
     * Scope to search items by name or description
     */
    public function scopeSearch($query, $search)
    {
        return $query->where(function ($q) use ($search) {
            $q->where('Name', 'LIKE', "%{$search}%")
              ->orWhere('Description', 'LIKE', "%{$search}%")
              ->orWhere('TastingNotes', 'LIKE', "%{$search}%");
        });
    }

    /**
     * Scope to get popular items (most ordered)
     */
    public function scopePopular($query, $limit = 10)
    {
        return $query->withCount('orderItems')
                    ->orderBy('order_items_count', 'desc')
                    ->limit($limit);
    }

    /**
     * Scope to get featured items (could be based on various criteria)
     */
    public function scopeFeatured($query)
    {
        return $query->where('Price', '>', 2000) // Premium items
                    ->withCount('orderItems')
                    ->orderBy('order_items_count', 'desc');
    }

    /**
     * Scope to sort by various criteria
     */
    public function scopeSortBy($query, $sortBy = 'name')
    {
        switch ($sortBy) {
            case 'price_low':
                return $query->orderBy('Price', 'asc');
            case 'price_high':
                return $query->orderBy('Price', 'desc');
            case 'popular':
                return $query->withCount('orderItems')->orderBy('order_items_count', 'desc');
            case 'newest':
                return $query->orderBy('ItemID', 'desc');
            default:
                return $query->orderBy('Name', 'asc');
        }
    }

    /**
     * Get the attributes that should be cast.
     */
    protected function casts(): array
    {
        return [
            'Price' => 'decimal:2',
            'RoastDates' => 'date',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    // ========================
    // Mutators & Accessors
    // ========================
    
    /**
     * Mutator: Ensure name is properly formatted
     */
    public function setNameAttribute($value)
    {
        $this->attributes['Name'] = ucwords(strtolower($value));
    }

    /**
     * Mutator: Ensure price is positive
     */
    public function setPriceAttribute($value)
    {
        $this->attributes['Price'] = max(0, (float) $value);
    }

    /**
     * Accessor: Get formatted price with currency
     */
    public function getFormattedPriceAttribute()
    {
        return 'LKR ' . number_format((float) $this->Price, 2);
    }

    /**
     * Accessor: Get price in different currency (example)
     */
    public function getPriceInUsdAttribute()
    {
        $usdRate = 0.0031; // Example conversion rate
        return round($this->Price * $usdRate, 2);
    }

    /**
     * Accessor: Get safe image URL
     */
    public function getImageUrlAttribute()
    {
        if (!$this->Image) {
            return asset('images/default.png');
        }
        
        // Extract filename from database path
        $filename = basename($this->Image);
        return asset('images/' . $filename);
    }

    /**
     * Accessor: Get short description
     */
    public function getShortDescriptionAttribute()
    {
        return Str::limit($this->Description, 100);
    }

    /**
     * Accessor: Check if item is premium
     */
    public function getIsPremiumAttribute()
    {
        return $this->Price >= 2500;
    }

    /**
     * Accessor: Get SEO-friendly slug
     */
    public function getSlugAttribute()
    {
        return Str::slug($this->Name . '-' . $this->ItemID);
    }

    /**
     * Create a new Eloquent Collection instance.
     */
    public function newCollection(array $models = [])
    {
        return new ItemCollection($models);
    }

    // ========================
    // Relationships
    // ========================
    
    public function cartItems()
    {
        return $this->hasMany(CartItem::class, 'ItemID', 'ItemID');
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class, 'ItemID', 'ItemID');
    }

    /**
     * Get all reviews for this item (polymorphic)
     */
    public function reviews()
    {
        return $this->morphMany(Review::class, 'reviewable');
    }

    /**
     * Get featured reviews
     */
    public function featuredReviews()
    {
        return $this->reviews()->featured()->with('user');
    }

    /**
     * Get average rating with optimized query
     */
    public function averageRating()
    {
        return $this->reviews()
                   ->selectRaw('AVG(rating) as avg_rating, COUNT(*) as review_count')
                   ->first();
    }

    /**
     * Get orders that include this item (has-many-through alternative)
     */
    public function orders()
    {
        return $this->belongsToMany(Order::class, 'order_items', 'ItemID', 'OrderID')
                    ->withPivot('Quantity');
    }

    /**
     * Get customers who bought this item
     */
    public function customers()
    {
        return $this->hasManyThrough(
            User::class,
            Order::class,
            'OrderID', // Foreign key on orders table
            'id', // Foreign key on users table  
            'ItemID', // Local key on items table
            'UserID' // Local key on orders table
        )->distinct();
    }
}
