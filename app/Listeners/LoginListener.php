<?php

namespace App\Listeners;

use App\Models\LoginHistory;
use Illuminate\Auth\Events\Login;
use Illuminate\Auth\Events\Failed;
use Illuminate\Auth\Events\Logout;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Request;
use Illuminate\Support\Facades\Session;

class LoginListener
{
    /**
     * Handle user login events.
     */
    public function handleLogin(Login $event): void
    {
        $loginHistory = LoginHistory::createFromRequest($event->user->id, true);
        
        // Store the login history ID in session for logout tracking
        Session::put('login_history_id', $loginHistory->id);
        
        // Update last login timestamp on user
        $event->user->update([
            'last_login_at' => now(),
            'last_login_ip' => Request::ip(),
        ]);
    }

    /**
     * Handle failed login attempts.
     */
    public function handleFailed(Failed $event): void
    {
        // Get user ID if credentials exist
        $userId = null;
        if (isset($event->credentials['email'])) {
            $user = \App\Models\User::where('email', $event->credentials['email'])->first();
            $userId = $user?->id;
        }

        LoginHistory::createFromRequest(
            $userId, 
            false, 
            'Invalid credentials'
        );
    }

    /**
     * Handle user logout events.
     */
    public function handleLogout(Logout $event): void
    {
        $loginHistoryId = Session::get('login_history_id');
        
        if ($loginHistoryId && $event->user) {
            $loginHistory = LoginHistory::find($loginHistoryId);
            
            if ($loginHistory) {
                $logoutTime = now();
                $sessionDuration = $logoutTime->diffInSeconds($loginHistory->login_at);
                
                $loginHistory->update([
                    'logout_at' => $logoutTime,
                    'session_duration' => $sessionDuration,
                ]);
            }
        }
        
        Session::forget('login_history_id');
    }

    /**
     * Register the listeners for the subscriber.
     */
    public function subscribe($events): array
    {
        return [
            Login::class => 'handleLogin',
            Failed::class => 'handleFailed',
            Logout::class => 'handleLogout',
        ];
    }
}