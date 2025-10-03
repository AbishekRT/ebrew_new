<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model as Eloquent;
use MongoDB\Laravel\Eloquent\SoftDeletes;
use Carbon\Carbon;

class CartActivityLog extends Eloquent
{
    use SoftDeletes;

    protected $connection = 'mongodb';
    protected $collection = 'cart_activity_logs';

    protected $fillable = [
        'user_id',
        'session_id',
        'session_start_time',
        'session_end_time', 
        'session_duration_minutes',
        'products_viewed',
        'products_added_to_cart',
        'products_removed_from_cart',
        'cart_abandonment_reason',
        'checkout_initiated',
        'checkout_completed',
        'total_cart_value',
        'device_info',
        'browser_info',
        'ip_address',
        'location_data',
        'referrer_source',
        'shopping_patterns',
        'time_spent_on_products',
        'conversion_funnel_stage',
        'cart_recovery_attempts',
        'promotional_codes_used',
        'payment_method_attempted',
        'abandoned_cart_reminder_sent',
        'session_metadata'
    ];

    protected $casts = [
        'products_viewed' => 'array',
        'products_added_to_cart' => 'array',
        'products_removed_from_cart' => 'array',
        'device_info' => 'array',
        'browser_info' => 'array',
        'location_data' => 'array',
        'shopping_patterns' => 'array',
        'time_spent_on_products' => 'array',
        'cart_recovery_attempts' => 'array',
        'promotional_codes_used' => 'array',
        'session_metadata' => 'array',
        'session_start_time' => 'datetime',
        'session_end_time' => 'datetime',
        'checkout_initiated' => 'boolean',
        'checkout_completed' => 'boolean',
        'total_cart_value' => 'decimal:2',
        'session_duration_minutes' => 'integer',
        'abandoned_cart_reminder_sent' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    protected $dates = ['created_at', 'updated_at', 'deleted_at', 'session_start_time', 'session_end_time'];

    // ========================
    // Advanced MongoDB Queries
    // ========================

    /**
     * Get shopping sessions analytics for a user
     */
    public static function getUserShoppingSessions($userId, $days = 30)
    {
        $startDate = Carbon::now()->subDays($days);

        return self::raw(function($collection) use ($userId, $startDate) {
            return $collection->aggregate([
                [
                    '$match' => [
                        'user_id' => (int) $userId,
                        'created_at' => ['$gte' => $startDate]
                    ]
                ],
                [
                    '$group' => [
                        '_id' => '$user_id',
                        'total_sessions' => ['$sum' => 1],
                        'completed_purchases' => [
                            '$sum' => [
                                '$cond' => [
                                    ['$eq' => ['$checkout_completed', true]],
                                    1,
                                    0
                                ]
                            ]
                        ],
                        'abandoned_carts' => [
                            '$sum' => [
                                '$cond' => [
                                    ['$and' => [
                                        ['$eq' => ['$checkout_initiated', true]],
                                        ['$eq' => ['$checkout_completed', false]]
                                    ]],
                                    1,
                                    0
                                ]
                            ]
                        ],
                        'total_products_viewed' => [
                            '$sum' => [
                                '$size' => [
                                    '$ifNull' => ['$products_viewed', []]
                                ]
                            ]
                        ],
                        'total_products_added' => [
                            '$sum' => [
                                '$size' => [
                                    '$ifNull' => ['$products_added_to_cart', []]
                                ]
                            ]
                        ],
                        'avg_session_duration' => ['$avg' => '$session_duration_minutes'],
                        'total_cart_value' => ['$sum' => '$total_cart_value'],
                        'peak_shopping_hours' => ['$push' => ['$hour' => '$session_start_time']],
                        'preferred_devices' => ['$push' => '$device_info.type'],
                        'last_activity' => ['$max' => '$session_end_time']
                    ]
                ],
                [
                    '$addFields' => [
                        'conversion_rate' => [
                            '$multiply' => [
                                [
                                    '$divide' => ['$completed_purchases', '$total_sessions']
                                ],
                                100
                            ]
                        ],
                        'abandonment_rate' => [
                            '$multiply' => [
                                [
                                    '$divide' => ['$abandoned_carts', '$total_sessions']
                                ],
                                100
                            ]
                        ],
                        'avg_products_per_session' => [
                            '$divide' => ['$total_products_viewed', '$total_sessions']
                        ]
                    ]
                ]
            ]);
        })->first();
    }

    /**
     * Get peak shopping times analysis
     */
    public static function getPeakShoppingTimes($userId = null, $days = 30)
    {
        $startDate = Carbon::now()->subDays($days);
        $match = ['created_at' => ['$gte' => $startDate]];
        
        if ($userId) {
            $match['user_id'] = (int) $userId;
        }

        return self::raw(function($collection) use ($match) {
            return $collection->aggregate([
                [
                    '$match' => $match
                ],
                [
                    '$project' => [
                        'hour' => ['$hour' => '$session_start_time'],
                        'day_of_week' => ['$dayOfWeek' => '$session_start_time'],
                        'session_duration' => '$session_duration_minutes',
                        'conversion' => '$checkout_completed'
                    ]
                ],
                [
                    '$group' => [
                        '_id' => [
                            'hour' => '$hour',
                            'day_of_week' => '$day_of_week'
                        ],
                        'session_count' => ['$sum' => 1],
                        'avg_duration' => ['$avg' => '$session_duration'],
                        'conversion_count' => [
                            '$sum' => [
                                '$cond' => [
                                    ['$eq' => ['$conversion', true]],
                                    1,
                                    0
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    '$addFields' => [
                        'conversion_rate' => [
                            '$multiply' => [
                                [
                                    '$divide' => ['$conversion_count', '$session_count']
                                ],
                                100
                            ]
                        ]
                    ]
                ],
                [
                    '$sort' => [
                        'session_count' => -1
                    ]
                ]
            ]);
        })->toArray();
    }

    /**
     * Get cart abandonment analysis
     */
    public static function getCartAbandonmentAnalysis($userId = null, $days = 30)
    {
        $startDate = Carbon::now()->subDays($days);
        $match = ['created_at' => ['$gte' => $startDate]];
        
        if ($userId) {
            $match['user_id'] = (int) $userId;
        }

        return self::raw(function($collection) use ($match) {
            return $collection->aggregate([
                [
                    '$match' => $match
                ],
                [
                    '$group' => [
                        '_id' => '$cart_abandonment_reason',
                        'count' => ['$sum' => 1],
                        'avg_cart_value' => ['$avg' => '$total_cart_value'],
                        'avg_products_in_cart' => [
                            '$avg' => [
                                '$size' => [
                                    '$ifNull' => ['$products_added_to_cart', []]
                                ]
                            ]
                        ],
                        'recovery_rate' => [
                            '$avg' => [
                                '$size' => [
                                    '$ifNull' => ['$cart_recovery_attempts', []]
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    '$sort' => [
                        'count' => -1
                    ]
                ]
            ]);
        })->toArray();
    }

    /**
     * Get product performance analytics
     */
    public static function getProductPerformance($userId = null, $days = 30)
    {
        $startDate = Carbon::now()->subDays($days);
        $match = ['created_at' => ['$gte' => $startDate]];
        
        if ($userId) {
            $match['user_id'] = (int) $userId;
        }

        return self::raw(function($collection) use ($match) {
            return $collection->aggregate([
                [
                    '$match' => $match
                ],
                [
                    '$unwind' => '$products_added_to_cart'
                ],
                [
                    '$group' => [
                        '_id' => '$products_added_to_cart.product_id',
                        'product_name' => ['$first' => '$products_added_to_cart.name'],
                        'times_added' => ['$sum' => 1],
                        'total_quantity' => ['$sum' => '$products_added_to_cart.quantity'],
                        'avg_price' => ['$avg' => '$products_added_to_cart.price'],
                        'conversion_rate' => [
                            '$avg' => [
                                '$cond' => [
                                    ['$eq' => ['$checkout_completed', true]],
                                    1,
                                    0
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    '$sort' => [
                        'times_added' => -1
                    ]
                ],
                [
                    '$limit' => 20
                ]
            ]);
        })->toArray();
    }

    // ========================
    // Helper Methods  
    // ========================

    /**
     * Start a new shopping session
     */
    public static function startSession($userId, $sessionId, $deviceInfo = [], $locationData = [])
    {
        return self::create([
            'user_id' => $userId,
            'session_id' => $sessionId,
            'session_start_time' => now(),
            'device_info' => $deviceInfo,
            'location_data' => $locationData,
            'products_viewed' => [],
            'products_added_to_cart' => [],
            'products_removed_from_cart' => [],
            'checkout_initiated' => false,
            'checkout_completed' => false,
            'total_cart_value' => 0,
            'session_metadata' => [
                'user_agent' => request()->userAgent(),
                'ip' => request()->ip(),
                'referrer' => request()->header('referer')
            ]
        ]);
    }

    /**
     * Log product view
     */
    public function logProductView($productId, $productName, $price, $timeSpent = 0)
    {
        $products = $this->products_viewed ?? [];
        $products[] = [
            'product_id' => $productId,
            'name' => $productName,
            'price' => $price,
            'viewed_at' => now(),
            'time_spent_seconds' => $timeSpent
        ];
        
        $this->update(['products_viewed' => $products]);
        return $this;
    }

    /**
     * Log add to cart
     */
    public function logAddToCart($productId, $productName, $price, $quantity = 1)
    {
        $products = $this->products_added_to_cart ?? [];
        $products[] = [
            'product_id' => $productId,
            'name' => $productName,
            'price' => $price,
            'quantity' => $quantity,
            'added_at' => now()
        ];
        
        $this->update([
            'products_added_to_cart' => $products,
            'total_cart_value' => ($this->total_cart_value ?? 0) + ($price * $quantity)
        ]);
        
        return $this;
    }

    /**
     * Log remove from cart
     */
    public function logRemoveFromCart($productId, $productName, $price, $quantity = 1, $reason = null)
    {
        $products = $this->products_removed_from_cart ?? [];
        $products[] = [
            'product_id' => $productId,
            'name' => $productName,
            'price' => $price,
            'quantity' => $quantity,
            'removed_at' => now(),
            'reason' => $reason
        ];
        
        $this->update([
            'products_removed_from_cart' => $products,
            'total_cart_value' => max(0, ($this->total_cart_value ?? 0) - ($price * $quantity))
        ]);
        
        return $this;
    }

    /**
     * Mark checkout initiated
     */
    public function markCheckoutInitiated()
    {
        $this->update(['checkout_initiated' => true]);
        return $this;
    }

    /**
     * Mark checkout completed
     */
    public function markCheckoutCompleted()
    {
        $this->update([
            'checkout_completed' => true,
            'session_end_time' => now(),
            'session_duration_minutes' => $this->session_start_time ? 
                $this->session_start_time->diffInMinutes(now()) : 0
        ]);
        return $this;
    }

    /**
     * Mark cart abandoned
     */
    public function markCartAbandoned($reason = 'unknown')
    {
        $this->update([
            'cart_abandonment_reason' => $reason,
            'session_end_time' => now(),
            'session_duration_minutes' => $this->session_start_time ? 
                $this->session_start_time->diffInMinutes(now()) : 0
        ]);
        return $this;
    }

    // ========================
    // Relationships
    // ========================

    public function user()
    {
        return $this->belongsTo(\App\Models\User::class, 'user_id', 'id');
    }

    // ========================
    // Scopes
    // ========================

    public function scopeRecentSessions($query, $days = 30)
    {
        return $query->where('created_at', '>=', Carbon::now()->subDays($days));
    }

    public function scopeCompletedPurchases($query)
    {
        return $query->where('checkout_completed', true);
    }

    public function scopeAbandonedCarts($query)
    {
        return $query->where('checkout_initiated', true)
                    ->where('checkout_completed', false);
    }

    public function scopeByUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }
}