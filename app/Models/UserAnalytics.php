<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model as Eloquent;
use MongoDB\Laravel\Eloquent\SoftDeletes;
use Carbon\Carbon;

class UserAnalytics extends Eloquent
{
    use SoftDeletes;

    protected $connection = 'mongodb';
    protected $collection = 'user_analytics';

    protected $fillable = [
        'user_id',
        'session_data',
        'device_info',
        'location_data',
        'security_events',
        'preferences',
        'behavior_patterns',
        'api_usage',
        'login_patterns',
    ];

    protected $casts = [
        'session_data' => 'array',
        'device_info' => 'array',
        'location_data' => 'array',
        'security_events' => 'array',
        'preferences' => 'array',
        'behavior_patterns' => 'array',
        'api_usage' => 'array',
        'login_patterns' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    protected $dates = ['created_at', 'updated_at', 'deleted_at'];

    // ========================
    // Advanced MongoDB Queries
    // ========================

    /**
     * Get user security summary with complex aggregation
     */
    public static function getSecuritySummary($userId)
    {
        return self::raw(function($collection) use ($userId) {
            return $collection->aggregate([
                [
                    '$match' => ['user_id' => (int) $userId]
                ],
                [
                    '$group' => [
                        '_id' => '$user_id',
                        'total_sessions' => ['$sum' => 1],
                        'unique_devices' => ['$addToSet' => '$device_info.device_id'],
                        'login_locations' => ['$addToSet' => '$location_data.city'],
                        'security_incidents' => [
                            '$sum' => [
                                '$size' => [
                                    '$ifNull' => ['$security_events', []]
                                ]
                            ]
                        ],
                        'api_calls' => [
                            '$sum' => [
                                '$ifNull' => ['$api_usage.total_requests', 0]
                            ]
                        ],
                        'last_active' => ['$max' => '$updated_at'],
                        'risk_score' => [
                            '$avg' => [
                                '$ifNull' => ['$security_events.risk_level', 0]
                            ]
                        ]
                    ]
                ],
                [
                    '$addFields' => [
                        'device_count' => ['$size' => '$unique_devices'],
                        'location_count' => ['$size' => '$login_locations'],
                        'security_status' => [
                            '$switch' => [
                                'branches' => [
                                    [
                                        'case' => ['$gte' => ['$risk_score', 8]],
                                        'then' => 'high_risk'
                                    ],
                                    [
                                        'case' => ['$gte' => ['$risk_score', 5]],
                                        'then' => 'medium_risk'
                                    ]
                                ],
                                'default' => 'low_risk'
                            ]
                        ]
                    ]
                ]
            ]);
        })->first();
    }

    /**
     * Advanced behavior pattern analysis
     */
    public static function getBehaviorPatterns($userId, $days = 30)
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
                    '$project' => [
                        'hour_of_day' => ['$hour' => '$created_at'],
                        'day_of_week' => ['$dayOfWeek' => '$created_at'],
                        'api_endpoints' => '$api_usage.endpoints_used',
                        'session_duration' => '$session_data.duration_minutes',
                        'device_type' => '$device_info.type'
                    ]
                ],
                [
                    '$group' => [
                        '_id' => null,
                        'peak_hours' => [
                            '$push' => [
                                'hour' => '$hour_of_day',
                                'count' => 1
                            ]
                        ],
                        'preferred_days' => [
                            '$push' => [
                                'day' => '$day_of_week',
                                'count' => 1
                            ]
                        ],
                        'avg_session_duration' => ['$avg' => '$session_duration'],
                        'device_usage' => [
                            '$push' => [
                                'device' => '$device_type',
                                'count' => 1
                            ]
                        ],
                        'api_patterns' => ['$push' => '$api_endpoints']
                    ]
                ]
            ]);
        })->first();
    }

    /**
     * Real-time threat detection
     */
    public static function detectAnomalies($userId)
    {
        return self::raw(function($collection) use ($userId) {
            return $collection->aggregate([
                [
                    '$match' => ['user_id' => (int) $userId]
                ],
                [
                    '$sort' => ['created_at' => -1]
                ],
                [
                    '$limit' => 100
                ],
                [
                    '$group' => [
                        '_id' => '$user_id',
                        'recent_ips' => ['$addToSet' => '$location_data.ip_address'],
                        'recent_locations' => ['$addToSet' => '$location_data.city'],
                        'failed_attempts' => [
                            '$sum' => [
                                '$cond' => [
                                    ['$eq' => ['$security_events.type', 'failed_login']],
                                    1,
                                    0
                                ]
                            ]
                        ],
                        'suspicious_activities' => [
                            '$sum' => [
                                '$cond' => [
                                    ['$gte' => ['$security_events.risk_level', 7]],
                                    1,
                                    0
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    '$addFields' => [
                        'ip_diversity' => ['$size' => '$recent_ips'],
                        'location_diversity' => ['$size' => '$recent_locations'],
                        'anomaly_score' => [
                            '$add' => [
                                ['$multiply' => ['$failed_attempts', 2]],
                                ['$multiply' => ['$suspicious_activities', 3]],
                                ['$multiply' => [
                                    ['$subtract' => ['$ip_diversity', 1]], 
                                    1.5
                                ]]
                            ]
                        ]
                    ]
                ]
            ]);
        })->first();
    }

    // ========================
    // Relationships
    // ========================

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    // ========================
    // Helper Methods
    // ========================

    /**
     * Record API usage
     */
    public static function recordApiUsage($userId, $endpoint, $method, $responseTime, $statusCode)
    {
        $analytics = self::firstOrNew(['user_id' => $userId]);
        
        $apiUsage = $analytics->api_usage ?? [];
        $apiUsage['total_requests'] = ($apiUsage['total_requests'] ?? 0) + 1;
        $apiUsage['endpoints_used'][] = [
            'endpoint' => $endpoint,
            'method' => $method,
            'timestamp' => now(),
            'response_time' => $responseTime,
            'status_code' => $statusCode
        ];

        $analytics->api_usage = $apiUsage;
        $analytics->save();
    }

    /**
     * Record security event
     */
    public static function recordSecurityEvent($userId, $eventType, $riskLevel, $details = [])
    {
        $analytics = self::firstOrNew(['user_id' => $userId]);
        
        $securityEvents = $analytics->security_events ?? [];
        $securityEvents[] = [
            'type' => $eventType,
            'risk_level' => $riskLevel,
            'details' => $details,
            'timestamp' => now(),
            'resolved' => false
        ];

        $analytics->security_events = $securityEvents;
        $analytics->save();
    }
}