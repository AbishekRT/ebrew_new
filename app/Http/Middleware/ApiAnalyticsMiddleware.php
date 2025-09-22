<?php

namespace App\Http\Middleware;

use App\Models\UserAnalytics;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ApiAnalyticsMiddleware
{
    /**
     * Handle an incoming request and record API analytics
     */
    public function handle(Request $request, Closure $next)
    {
        $startTime = microtime(true);
        
        $response = $next($request);
        
        $endTime = microtime(true);
        $responseTime = round(($endTime - $startTime) * 1000, 2); // milliseconds

        // Record API usage if user is authenticated
        if (Auth::guard('sanctum')->check()) {
            $user = Auth::guard('sanctum')->user();
            
            UserAnalytics::recordApiUsage(
                $user->id,
                $request->path(),
                $request->method(),
                $responseTime,
                $response->getStatusCode()
            );
        }

        // Add security headers
        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('X-XSS-Protection', '1; mode=block');
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');

        return $response;
    }
}