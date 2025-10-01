<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class IsAdminMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Check if user is authenticated
        if (!Auth::check()) {
            return redirect()->route('login');
        }

        $user = Auth::user();
        
        // Debug logging (remove in production)
        \Log::info('Admin Middleware Debug', [
            'user_id' => $user->id,
            'user_email' => $user->email,
            'user_role' => $user->role ?? 'null',
            'is_admin_field' => $user->is_admin ?? 'null',
            'isAdmin_method' => $user->isAdmin(),
            'request_url' => $request->url()
        ]);

        // Check if user has admin role (using the User model method)
        if (!$user->isAdmin()) {
            abort(403, 'Access denied. Admin privileges required. User: ' . $user->email . ', Role: ' . $user->role . ', isAdmin: ' . ($user->isAdmin() ? 'true' : 'false'));
        }

        return $next($request);
    }
}
