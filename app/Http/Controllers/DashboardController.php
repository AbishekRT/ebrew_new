<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\ProductMySQL;
use App\Models\Order;
use App\Models\UserAnalytics;
use App\Models\UserFavorites;

class DashboardController extends Controller
{
    public function index()
    {
        // Get current logged-in user
        $user = Auth::user();

        // ===== EXISTING CONTENT (PRESERVED) =====
        // Example: Fetch last 3 orders of this user
        $orders = Order::where('UserID', $user->id)
                        ->orderBy('OrderDate', 'desc')
                        ->take(3)
                        ->get();

        // Fetch random 3 recommended products from MySQL
        try {
            $recommended = ProductMySQL::inRandomOrder()->take(3)->get();
        } catch (\Exception $e) {
            // If there's any issue, just set empty collection
            $recommended = collect([]);
        }

        // ===== NEW OUTSTANDING MONGODB FEATURES =====
        
        try {
            // MongoDB UserAnalytics - Advanced Document Structures
            $userAnalytics = UserAnalytics::getSecuritySummary($user->id);
            $behaviorPatterns = UserAnalytics::getBehaviorPatterns($user->id, 30);
            $anomalyData = UserAnalytics::detectAnomalies($user->id);
            
        } catch (\Exception $e) {
            // Fallback if MongoDB is not connected - still show dashboard
            $userAnalytics = [
                'total_sessions' => 0,
                'unique_devices' => [],
                'security_incidents' => 0,
                'risk_score' => 0,
                'security_status' => 'low_risk'
            ];
            $behaviorPatterns = [];
            $anomalyData = ['anomaly_score' => 0];
        }

        // Enhanced user statistics
        $userStats = [
            'total_orders' => $user->orders()->count(),
            'total_spent' => $user->totalSpent(),
            'account_age_hours' => round($user->created_at->diffInHours(now()), 1),
            'last_login' => $user->last_login_at,
            'security_score' => $userAnalytics['risk_score'] ?? 0,
            'active_sessions' => $user->getActiveSessionCount(),
        ];

        return view('dashboard', compact(
            // Existing data (preserved)
            'user', 
            'orders', 
            'recommended',
            // MongoDB security data
            'userAnalytics',
            'behaviorPatterns',
            'anomalyData',
            'userStats'
        ));
    }
}
