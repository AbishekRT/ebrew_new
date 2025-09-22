<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\LoginHistory;
use App\Models\UserAnalytics;
use App\Models\UserFavorites;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;
use Carbon\Carbon;

class ProfileController extends Controller
{
    /**
     * Get comprehensive user profile with advanced analytics
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // Load relationships
        $user->load([
            'orders' => function($q) {
                $q->orderBy('created_at', 'desc')->limit(5);
            },
            'loginHistories' => function($q) {
                $q->orderBy('login_at', 'desc')->limit(10);
            }
        ]);

        // Get MongoDB analytics
        $securitySummary = UserAnalytics::getSecuritySummary($user->id);
        $behaviorPatterns = UserAnalytics::getBehaviorPatterns($user->id, 30);
        $anomalyData = UserAnalytics::detectAnomalies($user->id);

        // Get current session info
        $currentToken = $request->user()->currentAccessToken();
        $sessionInfo = [
            'current_session' => [
                'id' => $currentToken->id,
                'name' => $currentToken->name,
                'created_at' => $currentToken->created_at,
                'last_used_at' => $currentToken->last_used_at,
                'expires_at' => $currentToken->expires_at,
                'abilities' => $currentToken->abilities,
            ],
            'session_duration' => $currentToken->created_at->diffInMinutes(now()),
            'estimated_remaining' => $currentToken->expires_at ? 
                now()->diffInMinutes($currentToken->expires_at) : null,
        ];

        // Calculate user statistics
        $userStats = [
            'total_orders' => $user->orders()->count(),
            'total_spent' => $user->orders()->sum('total_amount'),
            'avg_order_value' => $user->orders()->avg('total_amount'),
            'account_age_days' => $user->created_at->diffInDays(now()),
            'last_order_date' => $user->orders()->latest()->first()?->created_at,
            'favorite_categories' => $this->getUserFavoriteCategories($user->id),
        ];

        return response()->json([
            'status' => 'success',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->Role,
                    'phone' => $user->Phone,
                    'delivery_address' => $user->DeliveryAddress,
                    'email_verified_at' => $user->email_verified_at,
                    'two_factor_enabled' => !is_null($user->two_factor_secret),
                    'profile_photo_url' => $user->profile_photo_url,
                    'created_at' => $user->created_at,
                ],
                'statistics' => $userStats,
                'session_info' => $sessionInfo,
                'security_summary' => [
                    'total_sessions' => $securitySummary['total_sessions'] ?? 0,
                    'unique_devices' => count($securitySummary['unique_devices'] ?? []),
                    'login_locations' => $securitySummary['login_locations'] ?? [],
                    'security_incidents' => $securitySummary['security_incidents'] ?? 0,
                    'risk_score' => $securitySummary['risk_score'] ?? 0,
                    'security_status' => $securitySummary['security_status'] ?? 'low_risk',
                    'last_active' => $securitySummary['last_active'] ?? null,
                ],
                'behavior_insights' => [
                    'peak_usage_hours' => $this->analyzePeakHours($behaviorPatterns),
                    'preferred_days' => $this->analyzePreferredDays($behaviorPatterns),
                    'avg_session_duration' => $behaviorPatterns['avg_session_duration'] ?? 0,
                    'device_preferences' => $this->analyzeDeviceUsage($behaviorPatterns),
                ],
                'security_alerts' => [
                    'anomaly_score' => $anomalyData['anomaly_score'] ?? 0,
                    'recent_failed_attempts' => $anomalyData['failed_attempts'] ?? 0,
                    'ip_diversity' => count($anomalyData['recent_ips'] ?? []),
                    'location_diversity' => count($anomalyData['recent_locations'] ?? []),
                    'recommendations' => $this->getSecurityRecommendations($user, $anomalyData),
                ],
                'recent_activity' => [
                    'recent_orders' => $user->orders,
                    'recent_logins' => $user->loginHistories,
                ]
            ]
        ]);
    }

    /**
     * Get detailed login history with advanced analytics
     */
    public function loginHistory(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $request->validate([
            'days' => 'integer|min:1|max:365',
            'page' => 'integer|min:1',
            'per_page' => 'integer|min:1|max:100',
            'filter' => 'in:all,successful,failed,suspicious',
        ]);

        $days = $request->get('days', 30);
        $page = $request->get('page', 1);
        $perPage = $request->get('per_page', 20);
        $filter = $request->get('filter', 'all');

        // Build query with filters
        $query = LoginHistory::where('user_id', $user->id)
            ->where('login_at', '>=', now()->subDays($days));

        switch ($filter) {
            case 'successful':
                $query->where('successful', true);
                break;
            case 'failed':
                $query->where('successful', false);
                break;
            case 'suspicious':
                $query->whereJsonContains('session_data->security_level', '>', 7);
                break;
        }

        $loginHistory = $query->orderBy('login_at', 'desc')
            ->paginate($perPage, ['*'], 'page', $page);

        // Get aggregated statistics
        $stats = LoginHistory::where('user_id', $user->id)
            ->where('login_at', '>=', now()->subDays($days))
            ->selectRaw('
                COUNT(*) as total_attempts,
                SUM(CASE WHEN successful = 1 THEN 1 ELSE 0 END) as successful_logins,
                SUM(CASE WHEN successful = 0 THEN 1 ELSE 0 END) as failed_attempts,
                COUNT(DISTINCT ip_address) as unique_ips,
                COUNT(DISTINCT device_type) as unique_devices,
                AVG(session_duration) as avg_session_duration
            ')
            ->first();

        // Get MongoDB analytics for deeper insights
        $securityEvents = UserAnalytics::where('user_id', $user->id)
            ->where('created_at', '>=', now()->subDays($days))
            ->get()
            ->flatMap(function($analytics) {
                return $analytics->security_events ?? [];
            })
            ->sortByDesc('timestamp')
            ->take(50);

        // Analyze login patterns
        $loginPatterns = $this->analyzeLoginPatterns($user->id, $days);

        return response()->json([
            'status' => 'success',
            'data' => [
                'login_history' => $loginHistory->items(),
                'pagination' => [
                    'current_page' => $loginHistory->currentPage(),
                    'per_page' => $loginHistory->perPage(),
                    'total' => $loginHistory->total(),
                    'last_page' => $loginHistory->lastPage(),
                ],
                'statistics' => [
                    'total_attempts' => $stats->total_attempts,
                    'successful_logins' => $stats->successful_logins,
                    'failed_attempts' => $stats->failed_attempts,
                    'success_rate' => $stats->total_attempts > 0 ? 
                        round(($stats->successful_logins / $stats->total_attempts) * 100, 2) : 0,
                    'unique_ips' => $stats->unique_ips,
                    'unique_devices' => $stats->unique_devices,
                    'avg_session_duration_minutes' => round($stats->avg_session_duration ?? 0, 2),
                ],
                'security_events' => $securityEvents->values(),
                'login_patterns' => $loginPatterns,
                'risk_assessment' => $this->assessLoginRisk($user->id, $stats),
            ]
        ]);
    }

    /**
     * Get user favorites with advanced recommendations
     */
    public function favorites(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // Get user favorites from MongoDB
        $userFavorites = UserFavorites::where('user_id', $user->id)->first();
        
        if (!$userFavorites) {
            return response()->json([
                'status' => 'success',
                'data' => [
                    'favorites' => [],
                    'recommendations' => [],
                    'preferences_analysis' => null,
                    'total_favorites' => 0,
                ]
            ]);
        }

        // Get personalized recommendations
        $recommendations = UserFavorites::getPersonalizedRecommendations($user->id, 10);
        
        // Analyze preferences
        $preferencesAnalysis = UserFavorites::analyzePreferences($user->id);

        // Enhance favorites with additional data
        $enhancedFavorites = collect($userFavorites->favorites)->map(function($favorite) {
            return array_merge($favorite, [
                'days_since_added' => Carbon::parse($favorite['added_at'])->diffInDays(now()),
                'interaction_frequency' => $favorite['interaction_count'] ?? 1,
                'preference_strength' => $this->calculatePreferenceStrength($favorite),
            ]);
        });

        return response()->json([
            'status' => 'success',
            'data' => [
                'favorites' => $enhancedFavorites,
                'total_favorites' => count($userFavorites->favorites ?? []),
                'recommendations' => $recommendations,
                'preferences_analysis' => [
                    'top_categories' => $preferencesAnalysis['category_analysis'] ?? [],
                    'price_preferences' => $preferencesAnalysis['price_analysis'][0] ?? null,
                    'temporal_trends' => $preferencesAnalysis['temporal_analysis'] ?? [],
                    'diversity_score' => $userFavorites->recommendation_data['diversity_score'] ?? 0,
                ],
                'insights' => [
                    'most_loved_category' => $userFavorites->recommendation_data['top_category'] ?? null,
                    'average_price_range' => $this->calculateAveragePriceRange($userFavorites->favorites ?? []),
                    'seasonal_patterns' => $this->analyzeSeasonalPatterns($userFavorites->favorites ?? []),
                    'recommendation_accuracy' => $this->calculateRecommendationAccuracy($user->id),
                ]
            ]
        ]);
    }

    /**
     * Add item to favorites with advanced tracking
     */
    public function addToFavorites(Request $request): JsonResponse
    {
        $request->validate([
            'item_id' => 'required|integer',
            'item_name' => 'required|string',
            'item_price' => 'required|numeric',
            'category' => 'required|string',
            'brand' => 'string|nullable',
            'additional_data' => 'array|nullable',
        ]);

        $user = $request->user();
        
        $itemData = [
            'item_id' => $request->item_id,
            'name' => $request->item_name,
            'price' => $request->item_price,
            'category' => $request->category,
            'brand' => $request->brand,
            'additional_data' => $request->additional_data ?? [],
        ];

        $userFavorites = UserFavorites::addToFavorites($user->id, $itemData);

        // Record the action in analytics
        UserAnalytics::recordApiUsage(
            $user->id, 
            '/api/profile/favorites', 
            'POST', 
            0, 
            200
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Item added to favorites successfully',
            'data' => [
                'total_favorites' => count($userFavorites->favorites ?? []),
                'category_updated' => $userFavorites->categories_preference,
            ]
        ]);
    }

    // ========================
    // Helper Methods
    // ========================

    private function getUserFavoriteCategories($userId): array
    {
        $userFavorites = UserFavorites::where('user_id', $userId)->first();
        return $userFavorites->categories_preference ?? [];
    }

    private function analyzePeakHours($behaviorPatterns): array
    {
        if (!isset($behaviorPatterns['peak_hours'])) return [];
        
        $hourCounts = [];
        foreach ($behaviorPatterns['peak_hours'] as $entry) {
            $hour = $entry['hour'];
            $hourCounts[$hour] = ($hourCounts[$hour] ?? 0) + 1;
        }
        
        arsort($hourCounts);
        return array_slice($hourCounts, 0, 3, true);
    }

    private function analyzePreferredDays($behaviorPatterns): array
    {
        if (!isset($behaviorPatterns['preferred_days'])) return [];
        
        $dayCounts = [];
        foreach ($behaviorPatterns['preferred_days'] as $entry) {
            $day = $entry['day'];
            $dayCounts[$day] = ($dayCounts[$day] ?? 0) + 1;
        }
        
        arsort($dayCounts);
        return $dayCounts;
    }

    private function analyzeDeviceUsage($behaviorPatterns): array
    {
        if (!isset($behaviorPatterns['device_usage'])) return [];
        
        $deviceCounts = [];
        foreach ($behaviorPatterns['device_usage'] as $entry) {
            $device = $entry['device'];
            $deviceCounts[$device] = ($deviceCounts[$device] ?? 0) + 1;
        }
        
        arsort($deviceCounts);
        return $deviceCounts;
    }

    private function getSecurityRecommendations(User $user, array $anomalyData = null): array
    {
        $recommendations = [];

        if ($anomalyData && $anomalyData['anomaly_score'] > 7) {
            $recommendations[] = 'Consider reviewing recent account activity';
        }

        if (!$user->two_factor_secret) {
            $recommendations[] = 'Enable two-factor authentication';
        }

        if ($anomalyData && count($anomalyData['recent_ips'] ?? []) > 3) {
            $recommendations[] = 'Multiple IP addresses detected - verify all logins are authorized';
        }

        return $recommendations;
    }

    private function analyzeLoginPatterns($userId, $days): array
    {
        // Complex pattern analysis would go here
        return [
            'most_common_times' => [],
            'unusual_activities' => [],
            'geographic_patterns' => [],
        ];
    }

    private function assessLoginRisk($userId, $stats): array
    {
        $riskScore = 0;
        
        if ($stats->failed_attempts > 5) $riskScore += 3;
        if ($stats->unique_ips > 5) $riskScore += 2;
        if ($stats->success_rate < 80) $riskScore += 2;
        
        $riskLevel = match(true) {
            $riskScore >= 6 => 'high',
            $riskScore >= 3 => 'medium',
            default => 'low'
        };

        return [
            'score' => $riskScore,
            'level' => $riskLevel,
            'factors' => $this->getRiskFactors($stats)
        ];
    }

    private function getRiskFactors($stats): array
    {
        $factors = [];
        
        if ($stats->failed_attempts > 5) {
            $factors[] = 'High number of failed login attempts';
        }
        
        if ($stats->unique_ips > 5) {
            $factors[] = 'Multiple IP addresses used';
        }

        return $factors;
    }

    private function calculatePreferenceStrength($favorite): float
    {
        $interactionCount = $favorite['interaction_count'] ?? 1;
        $daysSinceAdded = Carbon::parse($favorite['added_at'])->diffInDays(now());
        
        return min(10, ($interactionCount * 2) - ($daysSinceAdded * 0.1));
    }

    private function calculateAveragePriceRange($favorites): array
    {
        if (empty($favorites)) return ['min' => 0, 'max' => 0, 'avg' => 0];
        
        $prices = array_column($favorites, 'price');
        
        return [
            'min' => min($prices),
            'max' => max($prices),
            'avg' => array_sum($prices) / count($prices),
        ];
    }

    private function analyzeSeasonalPatterns($favorites): array
    {
        // Simplified seasonal analysis
        return [
            'spring' => 0,
            'summer' => 0,
            'autumn' => 0,
            'winter' => 0,
        ];
    }

    private function calculateRecommendationAccuracy($userId): float
    {
        // This would analyze how often recommended items are actually favorited
        return 0.75; // Placeholder
    }
}