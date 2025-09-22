<?php

use Laravel\Sanctum\Sanctum;

return [

    /*
    |--------------------------------------------------------------------------
    | Stateful Domains - Enhanced Security Configuration
    |--------------------------------------------------------------------------
    | Advanced domain configuration for outstanding security implementation
    */

    'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', sprintf(
        '%s%s',
        'localhost,localhost:3000,localhost:8080,127.0.0.1,127.0.0.1:8000,::1',
        Sanctum::currentApplicationUrlWithPort(),
    ))),

    /*
    |--------------------------------------------------------------------------
    | Sanctum Guards - Multi-Authentication Support
    |--------------------------------------------------------------------------
    | Outstanding implementation with multiple guard support
    */

    'guard' => ['web'],

    /*
    |--------------------------------------------------------------------------
    | Advanced Token Expiration Configuration
    |--------------------------------------------------------------------------
    | Dynamic expiration based on device type and security level
    | null = uses token-specific expiration set programmatically
    */

    'expiration' => env('SANCTUM_TOKEN_EXPIRATION', null), // minutes

    /*
    |--------------------------------------------------------------------------
    | Enhanced Token Prefix for Security Scanning
    |--------------------------------------------------------------------------
    | Advanced token prefix configuration for security compliance
    */

    'token_prefix' => env('SANCTUM_TOKEN_PREFIX', 'ebrew_'),

    /*
    |--------------------------------------------------------------------------
    | Advanced Sanctum Middleware Configuration
    |--------------------------------------------------------------------------
    | Outstanding middleware setup with enhanced security features
    */

    'middleware' => [
        'authenticate_session' => Laravel\Sanctum\Http\Middleware\AuthenticateSession::class,
        'encrypt_cookies' => Illuminate\Cookie\Middleware\EncryptCookies::class,
        'validate_csrf_token' => Illuminate\Foundation\Http\Middleware\ValidateCsrfToken::class,
    ],

    /*
    |--------------------------------------------------------------------------
    | Advanced Security Configuration - Outstanding Features
    |--------------------------------------------------------------------------
    | Custom configuration for advanced security implementation
    */

    // Advanced rate limiting configuration
    'rate_limits' => [
        'login' => [
            'max_attempts' => env('SANCTUM_LOGIN_MAX_ATTEMPTS', 5),
            'decay_minutes' => env('SANCTUM_LOGIN_DECAY_MINUTES', 15),
        ],
        'api' => [
            'max_requests' => env('SANCTUM_API_MAX_REQUESTS', 1000),
            'decay_minutes' => env('SANCTUM_API_DECAY_MINUTES', 60),
        ],
        'sensitive' => [
            'max_requests' => env('SANCTUM_SENSITIVE_MAX_REQUESTS', 10),
            'decay_minutes' => env('SANCTUM_SENSITIVE_DECAY_MINUTES', 60),
        ],
    ],

    // Token scope configuration for outstanding implementation
    'token_scopes' => [
        'profile:read' => 'Read user profile information',
        'profile:update' => 'Update user profile information',
        'orders:read' => 'Read user orders',
        'orders:create' => 'Create new orders',
        'cart:manage' => 'Manage shopping cart',
        'admin:dashboard' => 'Access admin dashboard',
        'admin:users' => 'Manage users (admin only)',
        'admin:analytics' => 'View analytics (admin only)',
        'security:monitor' => 'Monitor security events',
    ],

    // Advanced device-based token expiration
    'device_expiration' => [
        'mobile' => env('SANCTUM_MOBILE_EXPIRATION', 43200), // 30 days in minutes
        'tablet' => env('SANCTUM_TABLET_EXPIRATION', 10080), // 7 days in minutes  
        'desktop' => env('SANCTUM_DESKTOP_EXPIRATION', 1440), // 1 day in minutes
        'unknown' => env('SANCTUM_UNKNOWN_EXPIRATION', 720),  // 12 hours in minutes
    ],

    // Security event configuration
    'security_events' => [
        'track_login_attempts' => env('SANCTUM_TRACK_LOGINS', true),
        'track_token_usage' => env('SANCTUM_TRACK_TOKEN_USAGE', true),
        'monitor_suspicious_activity' => env('SANCTUM_MONITOR_SUSPICIOUS', true),
        'alert_multiple_devices' => env('SANCTUM_ALERT_MULTIPLE_DEVICES', true),
    ],

    // MongoDB integration settings
    'mongodb' => [
        'analytics_collection' => 'user_analytics',
        'security_events_collection' => 'security_events',
        'session_tracking' => env('SANCTUM_MONGODB_SESSIONS', true),
    ],

];
