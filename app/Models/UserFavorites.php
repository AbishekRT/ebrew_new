<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model as Eloquent;
use MongoDB\BSON\ObjectId;

class UserFavorites extends Eloquent
{
    protected $connection = 'mongodb';
    protected $collection = 'user_favorites';

    protected $fillable = [
        'user_id',
        'favorites',
        'categories_preference',
        'recommendation_data',
        'interaction_history',
    ];

    protected $casts = [
        'favorites' => 'array',
        'categories_preference' => 'array', 
        'recommendation_data' => 'array',
        'interaction_history' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ========================
    // Advanced MongoDB Aggregations
    // ========================

    /**
     * Get personalized recommendations using complex aggregation
     */
    public static function getPersonalizedRecommendations($userId, $limit = 10)
    {
        return self::raw(function($collection) use ($userId, $limit) {
            return $collection->aggregate([
                [
                    '$match' => ['user_id' => (int) $userId]
                ],
                [
                    '$unwind' => '$favorites'
                ],
                [
                    '$group' => [
                        '_id' => '$favorites.category',
                        'avg_price_range' => ['$avg' => '$favorites.price'],
                        'preferred_brands' => ['$addToSet' => '$favorites.brand'],
                        'interaction_score' => [
                            '$avg' => '$favorites.interaction_score'
                        ]
                    ]
                ],
                [
                    '$sort' => ['interaction_score' => -1]
                ],
                [
                    '$limit' => $limit
                ],
                [
                    '$lookup' => [
                        'from' => 'products',
                        'let' => [
                            'category' => '$_id',
                            'price_range' => '$avg_price_range',
                            'brands' => '$preferred_brands'
                        ],
                        'pipeline' => [
                            [
                                '$match' => [
                                    '$expr' => [
                                        '$and' => [
                                            ['$eq' => ['$category', '$$category']],
                                            ['$gte' => ['$price', ['$multiply' => ['$$price_range', 0.8]]]],
                                            ['$lte' => ['$price', ['$multiply' => ['$$price_range', 1.2]]]],
                                        ]
                                    ]
                                ]
                            ],
                            ['$limit' => 3]
                        ],
                        'as' => 'recommended_products'
                    ]
                ]
            ]);
        });
    }

    /**
     * Analyze user preferences with advanced aggregation
     */
    public static function analyzePreferences($userId)
    {
        return self::raw(function($collection) use ($userId) {
            return $collection->aggregate([
                [
                    '$match' => ['user_id' => (int) $userId]
                ],
                [
                    '$unwind' => '$favorites'
                ],
                [
                    '$facet' => [
                        'category_analysis' => [
                            [
                                '$group' => [
                                    '_id' => '$favorites.category',
                                    'count' => ['$sum' => 1],
                                    'avg_price' => ['$avg' => '$favorites.price'],
                                    'total_interactions' => ['$sum' => '$favorites.interaction_count']
                                ]
                            ],
                            ['$sort' => ['count' => -1]]
                        ],
                        'price_analysis' => [
                            [
                                '$group' => [
                                    '_id' => null,
                                    'min_price' => ['$min' => '$favorites.price'],
                                    'max_price' => ['$max' => '$favorites.price'],
                                    'avg_price' => ['$avg' => '$favorites.price'],
                                    'price_ranges' => [
                                        '$push' => [
                                            '$switch' => [
                                                'branches' => [
                                                    [
                                                        'case' => ['$lt' => ['$favorites.price', 1000]],
                                                        'then' => 'budget'
                                                    ],
                                                    [
                                                        'case' => ['$lt' => ['$favorites.price', 3000]],
                                                        'then' => 'mid-range'
                                                    ]
                                                ],
                                                'default' => 'premium'
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        'temporal_analysis' => [
                            [
                                '$group' => [
                                    '_id' => [
                                        'month' => ['$month' => '$favorites.added_at'],
                                        'year' => ['$year' => '$favorites.added_at']
                                    ],
                                    'favorites_added' => ['$sum' => 1]
                                ]
                            ],
                            ['$sort' => ['_id.year' => -1, '_id.month' => -1]]
                        ]
                    ]
                ]
            ]);
        })->first();
    }

    // ========================
    // Helper Methods
    // ========================

    /**
     * Add item to favorites with advanced tracking
     */
    public static function addToFavorites($userId, $itemData)
    {
        $userFavorites = self::firstOrNew(['user_id' => $userId]);
        
        $favorites = $userFavorites->favorites ?? [];
        $favorites[] = array_merge($itemData, [
            'added_at' => now(),
            'interaction_score' => 1,
            'interaction_count' => 1,
        ]);

        $userFavorites->favorites = $favorites;
        $userFavorites->save();

        // Update recommendation data
        self::updateRecommendationData($userId);

        return $userFavorites;
    }

    /**
     * Update recommendation algorithms data
     */
    private static function updateRecommendationData($userId)
    {
        $userFavorites = self::where('user_id', $userId)->first();
        if (!$userFavorites) return;

        // Calculate category preferences
        $categoryPrefs = [];
        foreach ($userFavorites->favorites ?? [] as $fav) {
            $category = $fav['category'] ?? 'unknown';
            $categoryPrefs[$category] = ($categoryPrefs[$category] ?? 0) + 1;
        }

        arsort($categoryPrefs);
        
        $userFavorites->categories_preference = $categoryPrefs;
        $userFavorites->recommendation_data = [
            'last_updated' => now(),
            'total_favorites' => count($userFavorites->favorites ?? []),
            'top_category' => array_key_first($categoryPrefs),
            'diversity_score' => count($categoryPrefs),
        ];

        $userFavorites->save();
    }
}