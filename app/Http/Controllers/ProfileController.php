<?php

namespace App\Http\Controllers;

use App\Models\LoginHistory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules;

class ProfileController extends Controller
{
    /**
     * Show the form for editing the specified resource.
     */
    public function edit()
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();
        $loginHistory = $user->recentLoginAttempts(30)->limit(10)->get();
        $activeSessionsCount = $user->getActiveSessionCount();
        $sessionStats = $user->getSessionStats();

        return view('profile.edit', [
            'user' => $user,
            'loginHistory' => $loginHistory,
            'activeSessionsCount' => $activeSessionsCount,
            'sessionStats' => $sessionStats,
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request)
    {
        $user = Auth::user();

        $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email,' . $user->id],
        ]);

        $user->name = $request->name;
        $user->email = $request->email;

        if ($user->isDirty('email')) {
            $user->email_verified_at = null;
        }

        $user->save();

        return redirect()->route('profile.edit')->with('status', 'profile-updated');
    }

    /**
     * Update the user's password.
     */
    public function updatePassword(Request $request)
    {
        $request->validate([
            'current_password' => ['required', 'current_password'],
            'password' => ['required', 'confirmed', Rules\Password::defaults()],
        ]);

        Auth::user()->update([
            'password' => Hash::make($request->password),
        ]);

        return redirect()->route('profile.edit')->with('status', 'password-updated');
    }

    /**
     * Show user's login history
     */
    public function loginHistory()
    {
        $user = Auth::user();
        
        Gate::authorize('view-login-history', $user);

        $loginHistory = $user->loginHistories()
            ->orderBy('login_at', 'desc')
            ->paginate(15);

        $stats = $user->getSessionStats();

        return view('profile.login-history', [
            'loginHistory' => $loginHistory,
            'stats' => $stats,
            'user' => $user,
        ]);
    }

    /**
     * Update user's security settings
     */
    public function updateSecuritySettings(Request $request)
    {
        $user = Auth::user();
        
        $request->validate([
            'login_notifications' => 'boolean',
            'failed_attempt_notifications' => 'boolean',
            'session_timeout' => 'integer|min:5|max:1440', // 5 minutes to 24 hours
            'require_device_verification' => 'boolean',
        ]);

        $user->updateSecuritySettings([
            'login_notifications' => $request->boolean('login_notifications'),
            'failed_attempt_notifications' => $request->boolean('failed_attempt_notifications'),
            'session_timeout' => $request->integer('session_timeout', 60),
            'require_device_verification' => $request->boolean('require_device_verification'),
            'updated_at' => now(),
        ]);

        return redirect()->route('profile.edit')->with('status', 'security-settings-updated');
    }

    /**
     * Terminate all other sessions
     */
    public function terminateOtherSessions(Request $request)
    {
        $request->validate([
            'password' => ['required', 'current_password'],
        ]);

        $user = Auth::user();
        $currentSessionId = session()->getId();

        // Update all active sessions except current to be logged out
        $user->loginHistories()
            ->whereNull('logout_at')
            ->where('successful', true)
            ->where('session_duration', '!=', $currentSessionId) // This would need proper session tracking
            ->update([
                'logout_at' => now(),
                'session_duration' => now()->diffInSeconds(
                    $user->loginHistories()
                        ->whereNull('logout_at')
                        ->where('successful', true)
                        ->first()
                        ->login_at ?? now()
                )
            ]);

        return redirect()->route('profile.edit')->with('status', 'other-sessions-terminated');
    }

    /**
     * Download user data (GDPR compliance)
     */
    public function downloadData()
    {
        $user = Auth::user();
        
        $data = [
            'user_info' => [
                'name' => $user->name,
                'email' => $user->email,
                'created_at' => $user->created_at,
                'email_verified_at' => $user->email_verified_at,
                'last_login_at' => $user->last_login_at,
                'is_admin' => $user->is_admin,
            ],
            'security_settings' => $user->getSecuritySettings(),
            'login_history' => $user->loginHistories()
                ->select(['ip_address', 'device_type', 'browser', 'platform', 'successful', 'login_at', 'logout_at'])
                ->orderBy('login_at', 'desc')
                ->get()
                ->toArray(),
            'session_stats' => $user->getSessionStats(),
            'orders' => $user->orders()->with('orderItems.item')->get()->toArray(),
            'reviews' => $user->reviews()->with('item')->get()->toArray(),
        ];

        $filename = "user_data_{$user->id}_" . now()->format('Y-m-d_H-i-s') . '.json';

        return response()->json($data, 200, [
            'Content-Type' => 'application/json',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ]);
    }
}
