<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\LoginHistory;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class SecurityDashboardController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
        $this->middleware(function ($request, $next) {
            if (!Gate::allows('view-security-dashboard')) {
                abort(403, 'Unauthorized access to security dashboard.');
            }
            return $next($request);
        });
    }

    /**
     * Display the security dashboard
     */
    public function index()
    {
        $data = [
            'totalUsers' => User::count(),
            'adminUsers' => User::admins()->count(),
            'recentLogins' => LoginHistory::successful()
                ->with('user')
                ->orderBy('login_at', 'desc')
                ->limit(10)
                ->get(),
            'failedAttempts' => LoginHistory::failed()
                ->with('user')
                ->where('login_at', '>=', now()->subHours(24))
                ->orderBy('login_at', 'desc')
                ->limit(10)
                ->get(),
            'suspiciousUsers' => User::suspiciousActivity()
                ->with('failedLoginAttempts')
                ->get(),
            'activeSessionsCount' => LoginHistory::successful()
                ->whereNull('logout_at')
                ->count(),
            'loginStats' => $this->getLoginStats(),
            'deviceStats' => $this->getDeviceStats(),
        ];

        return view('admin.security-dashboard', $data);
    }

    /**
     * Get login statistics
     */
    private function getLoginStats(): array
    {
        $today = now()->startOfDay();
        $week = now()->subWeek();
        $month = now()->subMonth();

        return [
            'today' => [
                'successful' => LoginHistory::successful()
                    ->where('login_at', '>=', $today)
                    ->count(),
                'failed' => LoginHistory::failed()
                    ->where('login_at', '>=', $today)
                    ->count(),
            ],
            'week' => [
                'successful' => LoginHistory::successful()
                    ->where('login_at', '>=', $week)
                    ->count(),
                'failed' => LoginHistory::failed()
                    ->where('login_at', '>=', $week)
                    ->count(),
            ],
            'month' => [
                'successful' => LoginHistory::successful()
                    ->where('login_at', '>=', $month)
                    ->count(),
                'failed' => LoginHistory::failed()
                    ->where('login_at', '>=', $month)
                    ->count(),
            ],
        ];
    }

    /**
     * Get device and browser statistics
     */
    private function getDeviceStats(): array
    {
        $recentLogins = LoginHistory::successful()
            ->where('login_at', '>=', now()->subMonth())
            ->get();

        $deviceStats = collect($recentLogins->groupBy('device_type'))
            ->map(function ($group) { return $group->count(); })
            ->sortDesc();
        
        $browserStats = collect($recentLogins->groupBy('browser'))
            ->map(function ($group) { return $group->count(); })
            ->sortDesc();
            
        $platformStats = collect($recentLogins->groupBy('platform'))
            ->map(function ($group) { return $group->count(); })
            ->sortDesc();

        return [
            'devices' => $deviceStats,
            'browsers' => $browserStats,
            'platforms' => $platformStats,
        ];
    }

    /**
     * Show detailed user login history
     */
    public function userHistory(User $user)
    {
        Gate::authorize('view-login-history', $user);

        $loginHistory = $user->loginHistories()
            ->orderBy('login_at', 'desc')
            ->paginate(20);

        $stats = $user->getSessionStats();

        return view('admin.user-security-history', [
            'user' => $user,
            'loginHistory' => $loginHistory,
            'stats' => $stats,
        ]);
    }

    /**
     * Force logout a user's active sessions
     */
    public function forceLogout(User $user)
    {
        Gate::authorize('force-logout', $user);

        // Update all active sessions to be logged out
        $user->loginHistories()
            ->whereNull('logout_at')
            ->where('successful', true)
            ->update([
                'logout_at' => now(),
                'session_duration' => now()->diffInSeconds(LoginHistory::where('user_id', $user->id)
                    ->whereNull('logout_at')
                    ->first()
                    ->login_at ?? now())
            ]);

        return back()->with('success', "All active sessions for {$user->name} have been terminated.");
    }

    /**
     * Block suspicious IP addresses
     */
    public function blockIp(Request $request)
    {
        $request->validate([
            'ip_address' => 'required|ip'
        ]);

        // This would typically involve a more sophisticated blocking mechanism
        // For demonstration, we'll just mark failed attempts from this IP
        LoginHistory::where('ip_address', $request->ip_address)
            ->where('successful', false)
            ->update(['failure_reason' => 'IP Blocked by Admin']);

        return back()->with('success', "IP {$request->ip_address} has been flagged for blocking.");
    }

    /**
     * Export security report
     */
    public function exportReport(Request $request)
    {
        $fromDate = $request->get('from_date', now()->subMonth());
        $toDate = $request->get('to_date', now());

        $data = [
            'period' => ['from' => $fromDate, 'to' => $toDate],
            'summary' => [
                'total_logins' => LoginHistory::successful()
                    ->whereBetween('login_at', [$fromDate, $toDate])
                    ->count(),
                'failed_attempts' => LoginHistory::failed()
                    ->whereBetween('login_at', [$fromDate, $toDate])
                    ->count(),
                'unique_users' => LoginHistory::successful()
                    ->whereBetween('login_at', [$fromDate, $toDate])
                    ->distinct('user_id')
                    ->count(),
                'unique_ips' => LoginHistory::successful()
                    ->whereBetween('login_at', [$fromDate, $toDate])
                    ->distinct('ip_address')
                    ->count(),
            ],
            'failed_attempts_by_ip' => LoginHistory::failed()
                ->whereBetween('login_at', [$fromDate, $toDate])
                ->selectRaw('ip_address, COUNT(*) as attempts')
                ->groupBy('ip_address')
                ->orderBy('attempts', 'desc')
                ->limit(10)
                ->get(),
        ];

        return response()->json($data);
    }
}
