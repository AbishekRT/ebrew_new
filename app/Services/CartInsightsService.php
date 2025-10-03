<?php

namespace App\Services;

use App\Models\CartActivityLog;
use App\Models\UserAnalytics;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;

class CartInsightsService
{
    /**
     * Get comprehensive cart insights for a user
     */
    public function getUserCartInsights($userId, $days = 30)
    {
        $cacheKey = "user_cart_insights_{$userId}_{$days}";
        
        return Cache::remember($cacheKey, 300, function () use ($userId, $days) {
            $sessions = CartActivityLog::getUserShoppingSessions($userId, $days);
            $peakTimes = CartActivityLog::getPeakShoppingTimes($userId, $days);
            $abandonment = CartActivityLog::getCartAbandonmentAnalysis($userId, $days);
            $products = CartActivityLog::getProductPerformance($userId, $days);

            return [
                'summary' => $sessions,
                'peak_shopping_times' => $peakTimes,
                'abandonment_analysis' => $abandonment,
                'favorite_products' => $products,
                'insights_generated_at' => now()
            ];
        });
    }

    /**
     * Get shopping patterns analysis
     */
    public function getShoppingPatterns($userId, $days = 30)
    {
        $cacheKey = "shopping_patterns_{$userId}_{$days}";
        
        return Cache::remember($cacheKey, 300, function () use ($userId, $days) {
            $sessions = CartActivityLog::byUser($userId)
                ->recentSessions($days)
                ->orderBy('session_start_time')
                ->get();

            if ($sessions->isEmpty()) {
                return $this->getEmptyPatternsData();
            }

            $patterns = [
                'favorite_shopping_hours' => $this->analyzeFavoriteShoppingHours($sessions),
                'preferred_days' => $this->analyzePreferredDays($sessions),
                'session_duration_trends' => $this->analyzeSessionDurationTrends($sessions),
                'conversion_patterns' => $this->analyzeConversionPatterns($sessions),
                'device_preferences' => $this->analyzeDevicePreferences($sessions),
                'shopping_behavior_score' => $this->calculateShoppingBehaviorScore($sessions),
                'cart_value_trends' => $this->analyzeCartValueTrends($sessions),
                'product_discovery_patterns' => $this->analyzeProductDiscoveryPatterns($sessions)
            ];

            return $patterns;
        });
    }

    /**
     * Get real-time cart insights for dashboard
     */
    public function getDashboardInsights($userId)
    {
        $cacheKey = "dashboard_insights_{$userId}";
        
        return Cache::remember($cacheKey, 60, function () use ($userId) {
            $todaysSessions = CartActivityLog::byUser($userId)
                ->where('created_at', '>=', Carbon::today())
                ->get();

            $weekSessions = CartActivityLog::byUser($userId)
                ->recentSessions(7)
                ->get();

            $monthSessions = CartActivityLog::byUser($userId)
                ->recentSessions(30)
                ->get();

            return [
                'today' => [
                    'sessions' => $todaysSessions->count(),
                    'products_viewed' => $todaysSessions->sum(function($session) {
                        return count($session->products_viewed ?? []);
                    }),
                    'cart_value' => $todaysSessions->sum('total_cart_value'),
                    'conversions' => $todaysSessions->where('checkout_completed', true)->count()
                ],
                'week' => [
                    'sessions' => $weekSessions->count(),
                    'avg_session_duration' => round($weekSessions->avg('session_duration_minutes') ?? 0, 1),
                    'conversion_rate' => $this->calculateConversionRate($weekSessions),
                    'abandonment_rate' => $this->calculateAbandonmentRate($weekSessions)
                ],
                'month' => [
                    'total_sessions' => $monthSessions->count(),
                    'total_cart_value' => $monthSessions->sum('total_cart_value'),
                    'avg_products_per_session' => $this->calculateAvgProductsPerSession($monthSessions),
                    'favorite_shopping_hour' => $this->getFavoriteShoppingHour($monthSessions)
                ],
                'recommendations' => $this->generatePersonalizedRecommendations($userId, $monthSessions)
            ];
        });
    }

    /**
     * Analyze favorite shopping hours
     */
    private function analyzeFavoriteShoppingHours($sessions)
    {
        $hourCounts = [];
        
        foreach ($sessions as $session) {
            if ($session->session_start_time) {
                $hour = $session->session_start_time->format('H');
                $hourCounts[$hour] = ($hourCounts[$hour] ?? 0) + 1;
            }
        }
        
        arsort($hourCounts);
        
        return [
            'distribution' => $hourCounts,
            'peak_hour' => array_key_first($hourCounts) ?? 12,
            'peak_hour_percentage' => $hourCounts ? round((array_values($hourCounts)[0] / array_sum($hourCounts)) * 100, 1) : 0
        ];
    }

    /**
     * Analyze preferred shopping days
     */
    private function analyzePreferredDays($sessions)
    {
        $dayCounts = [];
        $dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        
        foreach ($sessions as $session) {
            if ($session->session_start_time) {
                $dayOfWeek = $session->session_start_time->dayOfWeek;
                $dayCounts[$dayNames[$dayOfWeek]] = ($dayCounts[$dayNames[$dayOfWeek]] ?? 0) + 1;
            }
        }
        
        arsort($dayCounts);
        
        return [
            'distribution' => $dayCounts,
            'favorite_day' => array_key_first($dayCounts) ?? 'Saturday',
            'weekend_vs_weekday' => $this->calculateWeekendVsWeekdayRatio($sessions)
        ];
    }

    /**
     * Analyze session duration trends
     */
    private function analyzeSessionDurationTrends($sessions)
    {
        $durations = $sessions->pluck('session_duration_minutes')->filter()->values();
        
        if ($durations->isEmpty()) {
            return ['avg' => 0, 'trend' => 'stable', 'categories' => []];
        }
        
        return [
            'avg_duration' => round($durations->avg(), 1),
            'median_duration' => $durations->median(),
            'max_duration' => $durations->max(),
            'trend' => $this->calculateDurationTrend($sessions),
            'categories' => [
                'quick_browse' => $durations->filter(function($d) { return $d < 5; })->count(),
                'regular_shopping' => $durations->filter(function($d) { return $d >= 5 && $d <= 30; })->count(),
                'extended_session' => $durations->filter(function($d) { return $d > 30; })->count(),
            ]
        ];
    }

    /**
     * Analyze conversion patterns
     */
    private function analyzeConversionPatterns($sessions)
    {
        $total = $sessions->count();
        $completed = $sessions->where('checkout_completed', true)->count();
        $initiated = $sessions->where('checkout_initiated', true)->count();
        $abandoned = $sessions->where('checkout_initiated', true)->where('checkout_completed', false)->count();
        
        return [
            'conversion_rate' => $total ? round(($completed / $total) * 100, 1) : 0,
            'cart_initiation_rate' => $total ? round(($initiated / $total) * 100, 1) : 0,
            'abandonment_rate' => $initiated ? round(($abandoned / $initiated) * 100, 1) : 0,
            'completion_efficiency' => $initiated ? round(($completed / $initiated) * 100, 1) : 0,
            'funnel_analysis' => [
                'sessions' => $total,
                'cart_initiated' => $initiated,
                'checkout_completed' => $completed,
                'abandoned' => $abandoned
            ]
        ];
    }

    /**
     * Analyze device preferences
     */
    private function analyzeDevicePreferences($sessions)
    {
        $deviceCounts = [];
        
        foreach ($sessions as $session) {
            $deviceType = $session->device_info['type'] ?? 'unknown';
            $deviceCounts[$deviceType] = ($deviceCounts[$deviceType] ?? 0) + 1;
        }
        
        arsort($deviceCounts);
        
        return [
            'distribution' => $deviceCounts,
            'preferred_device' => array_key_first($deviceCounts) ?? 'desktop',
            'mobile_percentage' => $this->calculateMobilePercentage($deviceCounts)
        ];
    }

    /**
     * Calculate shopping behavior score
     */
    private function calculateShoppingBehaviorScore($sessions)
    {
        if ($sessions->isEmpty()) return 0;
        
        $totalSessions = $sessions->count();
        $completedSessions = $sessions->where('checkout_completed', true)->count();
        $avgDuration = $sessions->avg('session_duration_minutes') ?? 0;
        $avgCartValue = $sessions->avg('total_cart_value') ?? 0;
        
        // Scoring algorithm (0-100)
        $conversionScore = $totalSessions ? ($completedSessions / $totalSessions) * 40 : 0;
        $engagementScore = min(($avgDuration / 30) * 30, 30); // Max 30 points for engagement
        $valueScore = min(($avgCartValue / 100) * 30, 30); // Max 30 points for cart value
        
        return round($conversionScore + $engagementScore + $valueScore, 1);
    }

    /**
     * Analyze cart value trends
     */
    private function analyzeCartValueTrends($sessions)
    {
        $values = $sessions->pluck('total_cart_value')->filter()->values();
        
        if ($values->isEmpty()) {
            return ['avg' => 0, 'trend' => 'stable', 'distribution' => []];
        }
        
        return [
            'avg_cart_value' => round($values->avg(), 2),
            'median_cart_value' => $values->median(),
            'max_cart_value' => $values->max(),
            'trend' => $this->calculateCartValueTrend($sessions),
            'distribution' => [
                'low_value' => $values->filter(function($v) { return $v < 50; })->count(),
                'medium_value' => $values->filter(function($v) { return $v >= 50 && $v <= 200; })->count(),
                'high_value' => $values->filter(function($v) { return $v > 200; })->count(),
            ]
        ];
    }

    /**
     * Analyze product discovery patterns
     */
    private function analyzeProductDiscoveryPatterns($sessions)
    {
        $totalViews = 0;
        $totalAdds = 0;
        $productViewCounts = [];
        
        foreach ($sessions as $session) {
            $viewed = count($session->products_viewed ?? []);
            $added = count($session->products_added_to_cart ?? []);
            
            $totalViews += $viewed;
            $totalAdds += $added;
            
            // Track individual products
            foreach ($session->products_viewed ?? [] as $product) {
                $productId = $product['product_id'] ?? 'unknown';
                $productViewCounts[$productId] = ($productViewCounts[$productId] ?? 0) + 1;
            }
        }
        
        arsort($productViewCounts);
        
        return [
            'avg_products_viewed_per_session' => $sessions->count() ? round($totalViews / $sessions->count(), 1) : 0,
            'view_to_cart_ratio' => $totalViews ? round(($totalAdds / $totalViews) * 100, 1) : 0,
            'most_viewed_products' => array_slice($productViewCounts, 0, 5, true),
            'discovery_efficiency' => $this->calculateDiscoveryEfficiency($totalViews, $totalAdds)
        ];
    }

    /**
     * Helper methods
     */
    private function calculateConversionRate($sessions)
    {
        $total = $sessions->count();
        $completed = $sessions->where('checkout_completed', true)->count();
        return $total ? round(($completed / $total) * 100, 1) : 0;
    }

    private function calculateAbandonmentRate($sessions)
    {
        $initiated = $sessions->where('checkout_initiated', true)->count();
        $abandoned = $sessions->where('checkout_initiated', true)->where('checkout_completed', false)->count();
        return $initiated ? round(($abandoned / $initiated) * 100, 1) : 0;
    }

    private function calculateAvgProductsPerSession($sessions)
    {
        if ($sessions->isEmpty()) return 0;
        
        $totalProducts = $sessions->sum(function($session) {
            return count($session->products_viewed ?? []);
        });
        
        return round($totalProducts / $sessions->count(), 1);
    }

    private function getFavoriteShoppingHour($sessions)
    {
        $hourCounts = [];
        
        foreach ($sessions as $session) {
            if ($session->session_start_time) {
                $hour = $session->session_start_time->format('H');
                $hourCounts[$hour] = ($hourCounts[$hour] ?? 0) + 1;
            }
        }
        
        arsort($hourCounts);
        return array_key_first($hourCounts) ?? 12;
    }

    private function calculateWeekendVsWeekdayRatio($sessions)
    {
        $weekendCount = 0;
        $weekdayCount = 0;
        
        foreach ($sessions as $session) {
            if ($session->session_start_time) {
                $dayOfWeek = $session->session_start_time->dayOfWeek;
                if ($dayOfWeek == 0 || $dayOfWeek == 6) { // Sunday or Saturday
                    $weekendCount++;
                } else {
                    $weekdayCount++;
                }
            }
        }
        
        $total = $weekendCount + $weekdayCount;
        return $total ? round(($weekendCount / $total) * 100, 1) : 0;
    }

    private function calculateDurationTrend($sessions)
    {
        if ($sessions->count() < 3) return 'stable';
        
        $recentSessions = $sessions->sortBy('session_start_time')->take(-5);
        $olderSessions = $sessions->sortBy('session_start_time')->take(5);
        
        $recentAvg = $recentSessions->avg('session_duration_minutes') ?? 0;
        $olderAvg = $olderSessions->avg('session_duration_minutes') ?? 0;
        
        if ($recentAvg > $olderAvg * 1.1) return 'increasing';
        if ($recentAvg < $olderAvg * 0.9) return 'decreasing';
        return 'stable';
    }

    private function calculateCartValueTrend($sessions)
    {
        if ($sessions->count() < 3) return 'stable';
        
        $recentSessions = $sessions->sortBy('session_start_time')->take(-5);
        $olderSessions = $sessions->sortBy('session_start_time')->take(5);
        
        $recentAvg = $recentSessions->avg('total_cart_value') ?? 0;
        $olderAvg = $olderSessions->avg('total_cart_value') ?? 0;
        
        if ($recentAvg > $olderAvg * 1.1) return 'increasing';
        if ($recentAvg < $olderAvg * 0.9) return 'decreasing';
        return 'stable';
    }

    private function calculateMobilePercentage($deviceCounts)
    {
        $total = array_sum($deviceCounts);
        $mobile = ($deviceCounts['mobile'] ?? 0) + ($deviceCounts['tablet'] ?? 0);
        return $total ? round(($mobile / $total) * 100, 1) : 0;
    }

    private function calculateDiscoveryEfficiency($totalViews, $totalAdds)
    {
        if ($totalViews == 0) return 0;
        $ratio = ($totalAdds / $totalViews) * 100;
        
        if ($ratio > 20) return 'excellent';
        if ($ratio > 10) return 'good';
        if ($ratio > 5) return 'fair';
        return 'poor';
    }

    private function generatePersonalizedRecommendations($userId, $sessions)
    {
        $recommendations = [];
        
        if ($sessions->isEmpty()) {
            return ['Start exploring our products to get personalized insights!'];
        }
        
        $conversionRate = $this->calculateConversionRate($sessions);
        $avgDuration = $sessions->avg('session_duration_minutes') ?? 0;
        $avgCartValue = $sessions->avg('total_cart_value') ?? 0;
        
        if ($conversionRate < 10) {
            $recommendations[] = "Your cart completion rate is {$conversionRate}%. Consider saving items for later or enabling cart reminders.";
        }
        
        if ($avgDuration < 5) {
            $recommendations[] = "Quick browsing detected! Try our product filters to find items faster.";
        }
        
        if ($avgCartValue < 50) {
            $recommendations[] = "Check out our bundle deals to get more value from your purchases.";
        }
        
        $peakHour = $this->getFavoriteShoppingHour($sessions);
        $recommendations[] = "You shop most at {$peakHour}:00. Look for flash sales during your active hours!";
        
        return $recommendations;
    }

    private function getEmptyPatternsData()
    {
        return [
            'favorite_shopping_hours' => ['distribution' => [], 'peak_hour' => 12, 'peak_hour_percentage' => 0],
            'preferred_days' => ['distribution' => [], 'favorite_day' => 'Saturday', 'weekend_vs_weekday' => 0],
            'session_duration_trends' => ['avg' => 0, 'trend' => 'stable', 'categories' => []],
            'conversion_patterns' => ['conversion_rate' => 0, 'cart_initiation_rate' => 0, 'abandonment_rate' => 0],
            'device_preferences' => ['distribution' => [], 'preferred_device' => 'desktop', 'mobile_percentage' => 0],
            'shopping_behavior_score' => 0,
            'cart_value_trends' => ['avg' => 0, 'trend' => 'stable', 'distribution' => []],
            'product_discovery_patterns' => ['avg_products_viewed_per_session' => 0, 'view_to_cart_ratio' => 0]
        ];
    }

    /**
     * Generate test data for demonstration
     */
    public function generateTestData($userId, $sessionsCount = 20)
    {
        $devices = ['desktop', 'mobile', 'tablet'];
        $locations = [
            ['city' => 'New York', 'country' => 'USA'],
            ['city' => 'Los Angeles', 'country' => 'USA'],
            ['city' => 'Chicago', 'country' => 'USA'],
            ['city' => 'Miami', 'country' => 'USA']
        ];
        
        $products = [
            ['id' => 1, 'name' => 'Premium Coffee Beans', 'price' => 24.99],
            ['id' => 2, 'name' => 'Artisan Coffee Mug', 'price' => 15.99],
            ['id' => 3, 'name' => 'Coffee Grinder Pro', 'price' => 89.99],
            ['id' => 4, 'name' => 'Espresso Machine', 'price' => 299.99],
            ['id' => 5, 'name' => 'Coffee Filter Set', 'price' => 12.99],
            ['id' => 6, 'name' => 'French Press', 'price' => 34.99],
            ['id' => 7, 'name' => 'Coffee Subscription Box', 'price' => 49.99],
            ['id' => 8, 'name' => 'Travel Coffee Tumbler', 'price' => 19.99]
        ];
        
        $abandonment_reasons = [
            'high_shipping_cost', 'found_better_price', 'changed_mind', 
            'security_concerns', 'complex_checkout', 'out_of_stock', 'payment_failed'
        ];
        
        for ($i = 0; $i < $sessionsCount; $i++) {
            $startTime = Carbon::now()->subDays(rand(1, 30))->subHours(rand(0, 23))->subMinutes(rand(0, 59));
            $sessionId = uniqid('session_');
            $device = $devices[array_rand($devices)];
            $location = $locations[array_rand($locations)];
            
            // Create session
            $session = CartActivityLog::create([
                'user_id' => $userId,
                'session_id' => $sessionId,
                'session_start_time' => $startTime,
                'device_info' => [
                    'type' => $device,
                    'device_id' => uniqid('device_'),
                    'browser' => 'Chrome',
                    'os' => $device === 'mobile' ? 'iOS' : 'Windows'
                ],
                'location_data' => $location,
                'products_viewed' => [],
                'products_added_to_cart' => [],
                'products_removed_from_cart' => [],
                'checkout_initiated' => false,
                'checkout_completed' => false,
                'total_cart_value' => 0,
                'session_metadata' => [
                    'user_agent' => 'Test User Agent',
                    'ip' => '192.168.1.' . rand(1, 254),
                    'referrer' => 'https://google.com'
                ]
            ]);
            
            // Add random product views (2-8 products per session)
            $viewCount = rand(2, 8);
            $viewedProducts = [];
            $addedProducts = [];
            $totalCartValue = 0;
            
            for ($v = 0; $v < $viewCount; $v++) {
                $product = $products[array_rand($products)];
                $viewedProducts[] = [
                    'product_id' => $product['id'],
                    'name' => $product['name'],
                    'price' => $product['price'],
                    'viewed_at' => $startTime->copy()->addMinutes($v * 2),
                    'time_spent_seconds' => rand(30, 300)
                ];
                
                // 40% chance to add viewed product to cart
                if (rand(1, 100) <= 40) {
                    $quantity = rand(1, 3);
                    $addedProducts[] = [
                        'product_id' => $product['id'],
                        'name' => $product['name'],
                        'price' => $product['price'],
                        'quantity' => $quantity,
                        'added_at' => $startTime->copy()->addMinutes($v * 2 + 1)
                    ];
                    $totalCartValue += $product['price'] * $quantity;
                }
            }
            
            // Determine session outcome
            $checkoutInitiated = count($addedProducts) > 0 && rand(1, 100) <= 70; // 70% initiate checkout if cart has items
            $checkoutCompleted = $checkoutInitiated && rand(1, 100) <= 60; // 60% complete if initiated
            
            $endTime = $startTime->copy()->addMinutes(rand(5, 45));
            $sessionDuration = $startTime->diffInMinutes($endTime);
            
            // Update session with final data
            $session->update([
                'products_viewed' => $viewedProducts,
                'products_added_to_cart' => $addedProducts,
                'checkout_initiated' => $checkoutInitiated,
                'checkout_completed' => $checkoutCompleted,
                'total_cart_value' => $totalCartValue,
                'session_end_time' => $endTime,
                'session_duration_minutes' => $sessionDuration,
                'cart_abandonment_reason' => $checkoutInitiated && !$checkoutCompleted ? 
                    $abandonment_reasons[array_rand($abandonment_reasons)] : null
            ]);
        }
        
        return "Generated {$sessionsCount} test shopping sessions for user {$userId}";
    }
}