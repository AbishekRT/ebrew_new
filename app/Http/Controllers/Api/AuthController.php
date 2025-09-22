<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\LoginHistory;
use App\Models\UserAnalytics;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;
use Carbon\Carbon;

class AuthController extends Controller
{
    /**
     * Advanced API Login with comprehensive security
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|min:8',
            'device_name' => 'required|string|max:255',
            'device_info' => 'array',
            'location_data' => 'array',
        ]);

        // Advanced rate limiting with multiple keys
        $rateLimitKey = 'login:' . $request->ip();
        $userRateLimitKey = 'login_user:' . $request->email;

        if (RateLimiter::tooManyAttempts($rateLimitKey, 5) || 
            RateLimiter::tooManyAttempts($userRateLimitKey, 3)) {
            
            $seconds = RateLimiter::availableIn($rateLimitKey);
            
            // Record security event
            $user = User::where('email', $request->email)->first();
            if ($user) {
                UserAnalytics::recordSecurityEvent(
                    $user->id, 
                    'rate_limit_exceeded', 
                    8, 
                    ['ip' => $request->ip(), 'attempts' => 5]
                );
            }

            return response()->json([
                'status' => 'error',
                'message' => 'Too many login attempts. Please try again in ' . $seconds . ' seconds.',
                'retry_after' => $seconds
            ], 429);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            RateLimiter::hit($rateLimitKey, 300); // 5 minutes
            RateLimiter::hit($userRateLimitKey, 600); // 10 minutes

            // Record failed login
            LoginHistory::create([
                'user_id' => $user ? $user->id : null,
                'ip_address' => $request->ip(),
                'device_type' => $request->device_name,
                'browser' => $request->userAgent(),
                'successful' => false,
                'login_at' => now(),
                'failure_reason' => 'invalid_credentials'
            ]);

            if ($user) {
                UserAnalytics::recordSecurityEvent(
                    $user->id, 
                    'failed_login', 
                    6, 
                    [
                        'ip' => $request->ip(),
                        'user_agent' => $request->userAgent(),
                        'device' => $request->device_name
                    ]
                );
            }

            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        // Clear rate limits on successful login
        RateLimiter::clear($rateLimitKey);
        RateLimiter::clear($userRateLimitKey);

        // Advanced token creation with dynamic abilities and expiration
        $abilities = $this->getUserAbilities($user);
        $deviceType = $this->detectDeviceType($request);
        $tokenExpiration = $this->calculateTokenExpiration($deviceType);
        
        $tokenName = sprintf('%s_%s_%s', 
            $request->device_name, 
            $deviceType, 
            now()->timestamp
        );
        
        $token = $user->createToken($tokenName, $abilities, $tokenExpiration);

        // Advanced session tracking
        $sessionData = [
            'device_type' => $deviceType,
            'browser' => $request->userAgent(),
            'ip_address' => $request->ip(),
            'location' => $request->location_data ?? [],
            'login_method' => 'api',
            'security_level' => $this->calculateSecurityLevel($request, $user),
            'session_id' => $token->accessToken->id,
        ];

        // Record successful login with enhanced data
        LoginHistory::create([
            'user_id' => $user->id,
            'ip_address' => $request->ip(),
            'device_type' => $request->device_name,
            'browser' => $request->userAgent(),
            'successful' => true,
            'login_at' => now(),
            'session_data' => json_encode($sessionData)
        ]);

        // Record in MongoDB analytics
        UserAnalytics::create([
            'user_id' => $user->id,
            'session_data' => [
                'session_id' => $token->accessToken->id,
                'login_timestamp' => now(),
                'expected_duration' => $this->estimateSessionDuration($user),
                'security_score' => $sessionData['security_level']
            ],
            'device_info' => array_merge($request->device_info ?? [], [
                'device_id' => $this->generateDeviceFingerprint($request),
                'type' => $deviceType,
                'user_agent' => $request->userAgent(),
                'screen_info' => $request->input('device_info.screen'),
            ]),
            'location_data' => array_merge($request->location_data ?? [], [
                'ip_address' => $request->ip(),
                'timestamp' => now(),
                'source' => 'api_login'
            ]),
            'security_events' => [
                [
                    'type' => 'successful_login',
                    'risk_level' => 2,
                    'timestamp' => now(),
                    'details' => $sessionData
                ]
            ],
            'api_usage' => [
                'total_requests' => 1,
                'endpoints_used' => [
                    [
                        'endpoint' => '/api/auth/login',
                        'method' => 'POST',
                        'timestamp' => now(),
                        'response_time' => 0 // Will be updated by middleware
                    ]
                ]
            ]
        ]);

        // Update user login stats
        $user->update([
            'last_login_at' => now(),
            'last_login_ip' => $request->ip(),
        ]);

        // Check for suspicious activity
        $anomalyCheck = UserAnalytics::detectAnomalies($user->id);
        $securityWarnings = $this->generateSecurityWarnings($anomalyCheck);

        return response()->json([
            'status' => 'success',
            'message' => 'Authentication successful',
            'data' => [
                'user' => $user->only(['id', 'name', 'email', 'Role']),
                'token' => $token->plainTextToken,
                'token_type' => 'Bearer',
                'expires_at' => $token->accessToken->expires_at,
                'abilities' => $abilities,
                'device_registered' => $tokenName,
                'session_info' => [
                    'session_id' => $token->accessToken->id,
                    'security_level' => $sessionData['security_level'],
                    'device_type' => $deviceType,
                    'estimated_duration' => $this->estimateSessionDuration($user)
                ],
                'security_status' => [
                    'warnings' => $securityWarnings,
                    'risk_score' => $anomalyCheck['anomaly_score'] ?? 0,
                    'recommendations' => $this->getSecurityRecommendations($user)
                ]
            ]
        ]);
    }

    /**
     * Enhanced logout with session analytics
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();
        $token = $request->user()->currentAccessToken();
        
        if ($token) {
            // Calculate session duration and update analytics
            $sessionStart = $token->created_at;
            $sessionDuration = now()->diffInMinutes($sessionStart);

            // Update login history
            LoginHistory::where('user_id', $user->id)
                ->whereNull('logout_at')
                ->where('created_at', '>=', $sessionStart)
                ->update([
                    'logout_at' => now(),
                    'session_duration' => $sessionDuration,
                ]);

            // Update MongoDB analytics
            UserAnalytics::where('user_id', $user->id)
                ->where('session_data.session_id', $token->id)
                ->update([
                    'session_data.logout_timestamp' => now(),
                    'session_data.duration_minutes' => $sessionDuration,
                    'session_data.logout_type' => 'manual'
                ]);

            // Record security event
            UserAnalytics::recordSecurityEvent(
                $user->id, 
                'manual_logout', 
                1, 
                [
                    'session_duration' => $sessionDuration,
                    'token_id' => $token->id,
                    'ip' => $request->ip()
                ]
            );
        }

        // Revoke current token
        $token->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Logged out successfully',
            'session_summary' => [
                'duration_minutes' => $sessionDuration ?? 0,
                'logout_type' => 'manual'
            ]
        ]);
    }

    /**
     * Advanced token management - list all active sessions
     */
    public function sessions(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $tokens = $user->tokens()->where('expires_at', '>', now())
            ->orderBy('last_used_at', 'desc')
            ->get()
            ->map(function ($token) use ($request) {
                return [
                    'id' => $token->id,
                    'name' => $token->name,
                    'abilities' => $token->abilities,
                    'created_at' => $token->created_at,
                    'last_used_at' => $token->last_used_at,
                    'expires_at' => $token->expires_at,
                    'is_current' => $token->id === $request->user()->currentAccessToken()->id,
                    'device_info' => $this->getTokenDeviceInfo($token),
                    'security_score' => $this->calculateTokenSecurity($token),
                ];
            });

        return response()->json([
            'status' => 'success',
            'data' => [
                'active_sessions' => $tokens,
                'total_sessions' => $tokens->count(),
                'security_summary' => [
                    'high_risk_sessions' => $tokens->where('security_score', '>', 7)->count(),
                    'unique_devices' => $tokens->pluck('device_info.device_type')->unique()->count(),
                    'oldest_session' => $tokens->min('created_at'),
                ]
            ]
        ]);
    }

    /**
     * Revoke specific session with security tracking
     */
    public function revokeSession(Request $request, $tokenId): JsonResponse
    {
        $user = $request->user();
        $token = $user->tokens()->find($tokenId);

        if (!$token) {
            return response()->json([
                'status' => 'error',
                'message' => 'Session not found'
            ], 404);
        }

        // Record security event before revoking
        UserAnalytics::recordSecurityEvent(
            $user->id, 
            'token_revoked', 
            3, 
            [
                'token_id' => $tokenId,
                'revoked_by' => 'user',
                'revoked_from_ip' => $request->ip(),
                'token_age_hours' => $token->created_at->diffInHours(now())
            ]
        );

        $token->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Session revoked successfully'
        ]);
    }

    // ========================
    // Advanced Helper Methods
    // ========================

    /**
     * Calculate dynamic user abilities based on role and security level
     */
    private function getUserAbilities(User $user): array
    {
        $baseAbilities = [
            'profile:read',
            'profile:update',
            'orders:read',
            'cart:manage'
        ];

        if ($user->isAdmin()) {
            return array_merge($baseAbilities, [
                'admin:dashboard',
                'users:manage',
                'analytics:read',
                'security:monitor'
            ]);
        }

        return $baseAbilities;
    }

    /**
     * Detect device type from request
     */
    private function detectDeviceType(Request $request): string
    {
        $userAgent = $request->userAgent();
        
        if (preg_match('/Mobile|Android|iPhone|iPad/', $userAgent)) {
            return 'mobile';
        } elseif (preg_match('/Tablet|iPad/', $userAgent)) {
            return 'tablet';
        }
        
        return 'desktop';
    }

    /**
     * Calculate dynamic token expiration based on device and security
     */
    private function calculateTokenExpiration(string $deviceType): Carbon
    {
        $hours = match($deviceType) {
            'mobile' => 720,  // 30 days
            'tablet' => 168,  // 7 days
            'desktop' => 24,  // 1 day
            default => 12
        };

        return now()->addHours($hours);
    }

    /**
     * Calculate security level for session
     */
    private function calculateSecurityLevel(Request $request, User $user): int
    {
        $score = 5; // Base score

        // Check IP reputation (simplified)
        if ($this->isKnownGoodIP($request->ip(), $user)) {
            $score -= 1;
        }

        // Check device recognition
        $deviceFingerprint = $this->generateDeviceFingerprint($request);
        if ($this->isKnownDevice($deviceFingerprint, $user)) {
            $score -= 2;
        }

        // Check time patterns
        if ($this->isTypicalLoginTime($user)) {
            $score -= 1;
        }

        return max(1, min(10, $score));
    }

    /**
     * Generate device fingerprint for tracking
     */
    private function generateDeviceFingerprint(Request $request): string
    {
        $components = [
            $request->userAgent(),
            $request->input('device_info.screen.width'),
            $request->input('device_info.screen.height'),
            $request->input('device_info.timezone'),
            $request->input('device_info.language')
        ];

        return hash('sha256', implode('|', array_filter($components)));
    }

    /**
     * Generate security warnings based on anomaly detection
     */
    private function generateSecurityWarnings(array $anomalyData = null): array
    {
        $warnings = [];

        if ($anomalyData && $anomalyData['anomaly_score'] > 5) {
            $warnings[] = 'Unusual login pattern detected';
        }

        if ($anomalyData && $anomalyData['ip_diversity'] > 3) {
            $warnings[] = 'Multiple IP addresses used recently';
        }

        if ($anomalyData && $anomalyData['failed_attempts'] > 2) {
            $warnings[] = 'Recent failed login attempts detected';
        }

        return $warnings;
    }

    /**
     * Get security recommendations for user
     */
    private function getSecurityRecommendations(User $user): array
    {
        $recommendations = [];

        // Check if 2FA is enabled
        if (!$user->two_factor_secret) {
            $recommendations[] = 'Enable two-factor authentication for enhanced security';
        }

        // Check recent password change
        if (!$user->password_changed_at || $user->password_changed_at->lt(now()->subMonths(3))) {
            $recommendations[] = 'Consider updating your password regularly';
        }

        return $recommendations;
    }

    // Additional helper methods (simplified for brevity)
    private function isKnownGoodIP(string $ip, User $user): bool { return true; }
    private function isKnownDevice(string $fingerprint, User $user): bool { return false; }
    private function isTypicalLoginTime(User $user): bool { return true; }
    private function estimateSessionDuration(User $user): int { return 120; }
    private function getTokenDeviceInfo($token): array { return ['device_type' => 'unknown']; }
    private function calculateTokenSecurity($token): int { return 5; }
}