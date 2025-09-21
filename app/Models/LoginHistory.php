<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Request;

class LoginHistory extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'ip_address',
        'user_agent',
        'device_type',
        'browser',
        'platform',
        'location',
        'successful',
        'failure_reason',
        'login_at',
        'logout_at',
        'session_duration'
    ];

    protected function casts(): array
    {
        return [
            'successful' => 'boolean',
            'login_at' => 'datetime',
            'logout_at' => 'datetime',
        ];
    }

    // ========================
    // Relationships
    // ========================

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // ========================
    // Scopes
    // ========================

    public function scopeSuccessful($query)
    {
        return $query->where('successful', true);
    }

    public function scopeFailed($query)
    {
        return $query->where('successful', false);
    }

    public function scopeRecent($query, $days = 30)
    {
        return $query->where('login_at', '>=', now()->subDays($days));
    }

    public function scopeFromIp($query, $ip)
    {
        return $query->where('ip_address', $ip);
    }

    // ========================
    // Helper Methods
    // ========================

    public static function createFromRequest($userId, $successful = true, $failureReason = null)
    {
        $userAgent = Request::userAgent();
        
        return self::create([
            'user_id' => $userId,
            'ip_address' => Request::ip(),
            'user_agent' => $userAgent,
            'device_type' => self::parseDeviceType($userAgent),
            'browser' => self::parseBrowser($userAgent),
            'platform' => self::parsePlatform($userAgent),
            'location' => self::getLocationFromIp(Request::ip()),
            'successful' => $successful,
            'failure_reason' => $failureReason,
            'login_at' => now(),
        ]);
    }

    private static function parseDeviceType($userAgent)
    {
        if (preg_match('/Mobile|Android|iPhone|iPad/', $userAgent)) {
            return 'Mobile';
        } elseif (preg_match('/Tablet/', $userAgent)) {
            return 'Tablet';
        }
        return 'Desktop';
    }

    private static function parseBrowser($userAgent)
    {
        if (strpos($userAgent, 'Chrome') !== false) return 'Chrome';
        if (strpos($userAgent, 'Firefox') !== false) return 'Firefox';
        if (strpos($userAgent, 'Safari') !== false) return 'Safari';
        if (strpos($userAgent, 'Edge') !== false) return 'Edge';
        return 'Unknown';
    }

    private static function parsePlatform($userAgent)
    {
        if (strpos($userAgent, 'Windows') !== false) return 'Windows';
        if (strpos($userAgent, 'Macintosh') !== false) return 'macOS';
        if (strpos($userAgent, 'Linux') !== false) return 'Linux';
        if (strpos($userAgent, 'Android') !== false) return 'Android';
        if (strpos($userAgent, 'iPhone') !== false) return 'iOS';
        return 'Unknown';
    }

    private static function getLocationFromIp($ip)
    {
        // Simple implementation - in production, use a service like MaxMind
        if ($ip === '127.0.0.1' || $ip === '::1') {
            return 'Local';
        }
        return 'Unknown';
    }

    // ========================
    // Accessors
    // ========================

    public function getSessionDurationHumanAttribute()
    {
        if (!$this->session_duration) {
            return null;
        }

        $hours = floor($this->session_duration / 3600);
        $minutes = floor(($this->session_duration % 3600) / 60);
        
        if ($hours > 0) {
            return "{$hours}h {$minutes}m";
        }
        
        return "{$minutes}m";
    }

    public function getIsActiveSessionAttribute()
    {
        return $this->logout_at === null;
    }
}
