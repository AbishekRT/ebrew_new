<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Fortify\TwoFactorAuthenticatable;
use Laravel\Jetstream\HasProfilePhoto;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable 
// implements MustVerifyEmail
{
    use HasApiTokens, HasFactory, HasProfilePhoto, Notifiable, TwoFactorAuthenticatable;

    protected $primaryKey = 'id'; // if your users table uses "id"
    // If you renamed to UserID, change this to: protected $primaryKey = 'UserID';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'Role', // Use correct column name 'Role' instead of 'role'
        'Phone', // Use correct column name 'Phone' instead of 'phone'  
        'DeliveryAddress', // Use correct column name 'DeliveryAddress' instead of 'delivery_address'
        'last_login_at',
        'last_login_ip',
        'is_admin',
        'security_settings',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'two_factor_recovery_codes',
        'two_factor_secret',
    ];

    /**
     * The accessors to append to the model's array form.
     *
     * @var array<int, string>
     */
    protected $appends = [
        'profile_photo_url',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'last_login_at' => 'datetime',
            'is_admin' => 'boolean',
            'security_settings' => 'json',
        ];
    }

    // ========================
    // Authentication Relationships
    // ========================

    /**
     * Get all login history records for this user
     */
    public function loginHistories()
    {
        return $this->hasMany(LoginHistory::class);
    }

    /**
     * Get recent login attempts (successful and failed)
     */
    public function recentLoginAttempts($days = 30)
    {
        return $this->hasMany(LoginHistory::class)
                    ->where('login_at', '>=', now()->subDays($days))
                    ->orderBy('login_at', 'desc');
    }

    /**
     * Get successful login sessions
     */
    public function successfulLogins()
    {
        return $this->hasMany(LoginHistory::class)
                    ->where('successful', true);
    }

    /**
     * Get failed login attempts
     */
    public function failedLoginAttempts()
    {
        return $this->hasMany(LoginHistory::class)
                    ->where('successful', false);
    }

    // ========================
    // Query Scopes
    // ========================
    
    /**
     * Scope to filter users by role
     */
    public function scopeRole($query, $role)
    {
        return $query->where('Role', $role); // Use correct column name
    }

    /**
     * Scope to get users with recent activity
     */
    public function scopeActiveUsers($query, $days = 30)
    {
        return $query->where('updated_at', '>=', now()->subDays($days))
                    ->orWhereHas('orders', function ($q) use ($days) {
                        $q->where('OrderDate', '>=', now()->subDays($days));
                    });
    }

    /**
     * Scope to get users with orders
     */
    public function scopeWithOrders($query)
    {
        return $query->whereHas('orders');
    }

    /**
     * Scope to get high-value customers
     */
    public function scopeHighValueCustomers($query, $minAmount = 10000)
    {
        return $query->whereHas('orders', function ($q) use ($minAmount) {
            $q->selectRaw('SUM(SubTotal) as total_spent')
              ->groupBy('UserID')
              ->havingRaw('SUM(SubTotal) >= ?', [$minAmount]);
        });
    }

    /**
     * Scope for admin users
     */
    public function scopeAdmins($query)
    {
        return $query->where('Role', 'admin'); // Use Role column
    }

    /**
     * Scope for users with recent suspicious activity
     */
    public function scopeSuspiciousActivity($query, $failedAttempts = 5)
    {
        return $query->whereHas('failedLoginAttempts', function ($q) use ($failedAttempts) {
            $q->where('login_at', '>=', now()->subHours(1))
              ->havingRaw('COUNT(*) >= ?', [$failedAttempts]);
        });
    }

    // ========================
    // Relationships
    // ========================

    public function carts()
    {
        return $this->hasMany(Cart::class, 'UserID', 'id'); 
        // if "UserID" is foreign key in carts table
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'UserID', 'id');
    }

    public function payments()
    {
        return $this->hasManyThrough(Payment::class, Order::class, 'UserID', 'OrderID', 'id', 'OrderID');
    }

    /**
     * Get all reviews written by this user
     */
    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    /**
     * Get items purchased by this user (many-to-many through orders)
     */
    public function purchasedItems()
    {
        return $this->belongsToMany(Item::class, 'order_items', 'OrderID', 'ItemID')
                    ->join('orders', 'order_items.OrderID', '=', 'orders.OrderID')
                    ->where('orders.UserID', $this->id)
                    ->withPivot('Quantity')
                    ->distinct();
    }

    /**
     * Get user's favorite items (based on multiple purchases)
     */
    public function favoriteItems()
    {
        return $this->belongsToMany(Item::class, 'order_items', 'OrderID', 'ItemID')
                    ->join('orders', 'order_items.OrderID', '=', 'orders.OrderID')
                    ->where('orders.UserID', $this->id)
                    ->selectRaw('items.*, COUNT(*) as purchase_count, SUM(order_items.Quantity) as total_quantity')
                    ->groupBy('items.ItemID')
                    ->having('purchase_count', '>', 1)
                    ->orderBy('purchase_count', 'desc');
    }

    // ========================
    // Authentication Helper Methods
    // ========================

    /**
     * Check if user is admin
     */
    public function isAdmin(): bool
    {
        return $this->Role === 'admin'; // Check Role column instead of is_admin
    }

    /**
     * Get user's security settings
     */
    public function getSecuritySettings(): array
    {
        return $this->security_settings ?: [];
    }

    /**
     * Update security settings
     */
    public function updateSecuritySettings(array $settings): void
    {
        $currentSettings = $this->getSecuritySettings();
        $this->update([
            'security_settings' => array_merge($currentSettings, $settings)
        ]);
    }

    /**
     * Check if user has recent failed login attempts
     */
    public function hasRecentFailedAttempts($threshold = 5, $minutes = 60): bool
    {
        return $this->failedLoginAttempts()
                    ->where('login_at', '>=', now()->subMinutes($minutes))
                    ->count() >= $threshold;
    }

    /**
     * Get user's total spent amount
     */
    public function totalSpent()
    {
        return $this->orders()->sum('SubTotal');
    }

    /**
     * Get user's recent orders
     */
    public function recentOrders($limit = 5)
    {
        return $this->orders()
                    ->with(['orderItems.item', 'payments'])
                    ->orderBy('OrderDate', 'desc')
                    ->limit($limit);
    }

    /**
     * Get active session count
     */
    public function getActiveSessionCount(): int
    {
        return $this->loginHistories()
                    ->whereNull('logout_at')
                    ->where('successful', true)
                    ->count();
    }

    /**
     * Get session statistics
     */
    public function getSessionStats(): array
    {
        $histories = $this->loginHistories()->successful()->get();
        
        return [
            'total_sessions' => $histories->count(),
            'average_session_duration' => $histories->whereNotNull('session_duration')->avg('session_duration'),
            'longest_session' => $histories->max('session_duration'),
            'unique_devices' => $histories->pluck('device_type')->unique()->count(),
            'unique_browsers' => $histories->pluck('browser')->unique()->count(),
            'unique_ips' => $histories->pluck('ip_address')->unique()->count(),
        ];
    }

    // ========================
    // Advanced API Methods for Outstanding Implementation
    // ========================

    /**
     * Check if user has specific API ability
     */
    public function hasApiAbility(string $ability): bool
    {
        $currentToken = $this->currentAccessToken();
        
        if (!$currentToken) {
            return false;
        }

        return $currentToken->can($ability);
    }

    /**
     * Get user's API security level
     */
    public function getApiSecurityLevel(): array
    {
        $recentFailures = $this->failedLoginAttempts()
            ->where('login_at', '>=', now()->subDays(7))
            ->count();

        $uniqueDevices = $this->loginHistories()
            ->where('login_at', '>=', now()->subDays(30))
            ->distinct('device_type')
            ->count();

        $riskScore = min(10, $recentFailures + ($uniqueDevices > 3 ? 2 : 0));

        return [
            'risk_score' => $riskScore,
            'security_level' => match(true) {
                $riskScore >= 7 => 'high_risk',
                $riskScore >= 4 => 'medium_risk',
                default => 'low_risk'
            },
            'recent_failures' => $recentFailures,
            'device_diversity' => $uniqueDevices,
            'two_factor_enabled' => !is_null($this->two_factor_secret),
        ];
    }

    /**
     * Create API token with advanced configuration
     */
    public function createApiToken(string $name, array $abilities = [], ?\DateTime $expiresAt = null): \Laravel\Sanctum\NewAccessToken
    {
        if (empty($abilities)) {
            $abilities = $this->getDefaultApiAbilities();
        }

        return $this->createToken($name, $abilities, $expiresAt);
    }

    /**
     * Get default API abilities based on user role
     */
    public function getDefaultApiAbilities(): array
    {
        $baseAbilities = [
            'profile:read',
            'profile:update', 
            'orders:read',
            'cart:manage'
        ];

        if ($this->isAdmin()) {
            return array_merge($baseAbilities, [
                'admin:dashboard',
                'admin:users',
                'admin:analytics',
                'security:monitor'
            ]);
        }

        return $baseAbilities;
    }

    /**
     * Revoke all API tokens except current
     */
    public function revokeOtherApiTokens($currentTokenId = null): int
    {
        $query = $this->tokens();
        
        if ($currentTokenId) {
            $query->where('id', '!=', $currentTokenId);
        }

        return $query->delete();
    }

    /**
     * Get API usage analytics
     */
    public function getApiUsageStats(int $days = 30): array
    {
        // This would integrate with UserAnalytics MongoDB model
        return [
            'total_requests' => 0,
            'endpoints_used' => [],
            'peak_usage_hours' => [],
            'average_response_time' => 0,
            'error_rate' => 0,
        ];
    }
}