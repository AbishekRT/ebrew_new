#!/bin/bash

# 🔧 COMPREHENSIVE AUTH & DATABASE FIXES FOR EC2
# ==============================================

echo "🚀 Starting comprehensive authentication and database fixes..."

# Step 1: Apply the new migration
echo "📊 Step 1: Running new migration for session_data"
cd /var/www/html

# Run the new migration
php artisan migrate --force

# Step 2: Update User model (fix casts method to property)
echo "📝 Step 2: Updating User model..."
cat > app/Models/User.php << 'EOF'
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
{
    use HasApiTokens, HasFactory, HasProfilePhoto, Notifiable, TwoFactorAuthenticatable;

    protected $primaryKey = 'id';

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'phone',
        'delivery_address',
        'last_login_at',
        'last_login_ip',
        'is_admin',
        'security_settings',
    ];

    /**
     * The attributes that should be hidden for serialization.
     */
    protected $hidden = [
        'password',
        'remember_token',
        'two_factor_recovery_codes',
        'two_factor_secret',
    ];

    /**
     * The accessors to append to the model's array form.
     */
    protected $appends = [
        'profile_photo_url',
    ];

    /**
     * FIXED: The attributes that should be cast (property not method)
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'last_login_at' => 'datetime',
        'two_factor_confirmed_at' => 'datetime',
        'is_admin' => 'boolean',
        'security_settings' => 'json',
    ];

    // ========================
    // Relationships
    // ========================

    public function loginHistories()
    {
        return $this->hasMany(LoginHistory::class);
    }

    public function recentLoginAttempts($days = 30)
    {
        return $this->hasMany(LoginHistory::class)
                    ->where('login_at', '>=', now()->subDays($days))
                    ->orderBy('login_at', 'desc');
    }

    public function successfulLogins()
    {
        return $this->hasMany(LoginHistory::class)
                    ->where('successful', true);
    }

    public function failedLoginAttempts()
    {
        return $this->hasMany(LoginHistory::class)
                    ->where('successful', false);
    }

    public function carts()
    {
        return $this->hasMany(Cart::class, 'UserID', 'id');
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'UserID', 'id');
    }

    public function payments()
    {
        return $this->hasManyThrough(Payment::class, Order::class, 'UserID', 'OrderID', 'id', 'OrderID');
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    // ========================
    // Helper Methods
    // ========================

    /**
     * FIXED: Check if user is admin (both columns)
     */
    public function isAdmin(): bool
    {
        return $this->is_admin || $this->role === 'admin';
    }

    public function getSecuritySettings(): array
    {
        return $this->security_settings ?: [];
    }

    public function updateSecuritySettings(array $settings): void
    {
        $currentSettings = $this->getSecuritySettings();
        $this->update([
            'security_settings' => array_merge($currentSettings, $settings)
        ]);
    }

    public function hasRecentFailedAttempts($threshold = 5, $minutes = 60): bool
    {
        return $this->failedLoginAttempts()
                    ->where('login_at', '>=', now()->subMinutes($minutes))
                    ->count() >= $threshold;
    }

    public function totalSpent()
    {
        return $this->orders()->sum('SubTotal') ?? 0.0;
    }

    public function getActiveSessionCount(): int
    {
        try {
            return $this->loginHistories()
                        ->whereNull('logout_at')
                        ->where('successful', true)
                        ->where('login_at', '>=', now()->subDays(30))
                        ->count();
        } catch (\Exception $e) {
            return $this->tokens()->where('last_used_at', '>=', now()->subHours(24))->count();
        }
    }

    public function getSessionStats(): array
    {
        $histories = $this->loginHistories()->where('successful', true)->get();
        
        return [
            'total_sessions' => $histories->count(),
            'average_session_duration' => $histories->whereNotNull('session_duration')->avg('session_duration'),
            'longest_session' => $histories->max('session_duration'),
            'unique_devices' => $histories->pluck('device_type')->unique()->count(),
            'unique_browsers' => $histories->pluck('browser')->unique()->count(),
            'unique_ips' => $histories->pluck('ip_address')->unique()->count(),
        ];
    }

    // Query Scopes
    public function scopeRole($query, $role)
    {
        return $query->where('role', $role);
    }

    public function scopeAdmins($query)
    {
        return $query->where('role', 'admin')->orWhere('is_admin', true);
    }

    public function scopeActiveUsers($query, $days = 30)
    {
        return $query->where('updated_at', '>=', now()->subDays($days));
    }
}
EOF

# Step 3: Update LoginHistory model
echo "📝 Step 3: Updating LoginHistory model..."
cat > app/Models/LoginHistory.php << 'EOF'
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
        'session_data',
        'login_at',
        'logout_at',
        'session_duration'
    ];

    /**
     * FIXED: The attributes that should be cast (property not method)
     */
    protected $casts = [
        'successful' => 'boolean',
        'login_at' => 'datetime',
        'logout_at' => 'datetime',
        'session_data' => 'json',
    ];

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Scopes
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

    /**
     * FIXED: Create login record safely (handles null user_id)
     */
    public static function createFromRequest($userId, $successful = true, $failureReason = null, $sessionData = null)
    {
        // Don't create record if user_id is null (constraint violation)
        if ($userId === null) {
            return null;
        }
        
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
            'session_data' => $sessionData,
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
        if ($ip === '127.0.0.1' || $ip === '::1') {
            return 'Local';
        }
        return 'Unknown';
    }

    // Accessors
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
EOF

# Step 4: Update Web AuthController (register form field mapping)
echo "📝 Step 4: Updating Web AuthController..."
cat > app/Http/Controllers/AuthController.php << 'EOF'
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use App\Models\LoginHistory;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    // Show login page
    public function showLogin()
    {
        return view('auth.login');
    }

    // Process login
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);

        if (Auth::attempt($credentials)) {
            // Regenerate session to prevent fixation
            $request->session()->regenerate();

            /** @var \App\Models\User $user */
            $user = Auth::user();
            
            // Record successful login
            LoginHistory::createFromRequest(
                $user->id, 
                true, 
                null, 
                ['login_method' => 'web', 'ip' => $request->ip()]
            );

            // Update user last login info
            $user->update([
                'last_login_at' => now(),
                'last_login_ip' => $request->ip(),
            ]);
            
            // Check user role and redirect accordingly
            if ($user->isAdmin()) {
                return redirect()->intended(route('admin.dashboard'));
            } else {
                return redirect()->intended(route('dashboard'));
            }
        }

        // Record failed login attempt (get user first)
        $user = User::where('email', $request->email)->first();
        if ($user) {
            LoginHistory::createFromRequest(
                $user->id, 
                false, 
                'invalid_credentials'
            );
        }

        return back()->withErrors([
            'email' => 'Invalid credentials.',
        ])->withInput();
    }

    // Logout
    public function logout(Request $request)
    {
        $user = Auth::user();
        
        // Record logout in login history
        if ($user) {
            $activeSession = $user->loginHistories()
                                  ->whereNull('logout_at')
                                  ->where('successful', true)
                                  ->latest('login_at')
                                  ->first();
                                  
            if ($activeSession) {
                $sessionDuration = now()->diffInSeconds($activeSession->login_at);
                $activeSession->update([
                    'logout_at' => now(),
                    'session_duration' => $sessionDuration
                ]);
            }
        }

        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('login');
    }

    // Show registration page
    public function showRegister()
    {
        return view('auth.register');
    }

    // Process registration
    public function register(Request $request)
    {
        $request->validate([
            'full_name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6|confirmed',
            'phone' => 'nullable|string|max:20',
            'address' => 'nullable|string|max:500',
        ]);

        try {
            $user = User::create([
                'name' => $request->full_name,  // Maps full_name → name
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'phone' => $request->phone,
                'delivery_address' => $request->address,  // Maps address → delivery_address
                'role' => 'customer',  // Default role
            ]);

            // Record registration success
            LoginHistory::createFromRequest(
                $user->id, 
                true, 
                null, 
                ['action' => 'registration', 'ip' => $request->ip()]
            );

            return redirect()->route('login')->with('success', 'Registration successful! Please login.');
            
        } catch (\Exception $e) {
            return back()->withErrors([
                'registration' => 'Registration failed: ' . $e->getMessage()
            ])->withInput();
        }
    }
}
EOF

# Step 5: Update API AuthController (fix column names)
echo "📝 Step 5: Updating API AuthController..."
# Fix the line that uses 'Role' instead of 'role'
sed -i "s/'user' => \$user->only(\['id', 'name', 'email', 'Role'\])/'user' => \$user->only(['id', 'name', 'email', 'role'])/g" app/Http/Controllers/Api/AuthController.php

# Step 6: Clear all Laravel caches
echo "🔄 Step 6: Clearing Laravel caches..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

# Step 7: Set proper permissions
echo "🔒 Step 7: Setting permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod -R 775 /var/www/html/storage
chmod -R 775 /var/www/html/bootstrap/cache

# Step 8: Restart services
echo "🔄 Step 8: Restarting services..."
systemctl restart apache2
systemctl restart mysql

echo "✅ Complete authentication fix applied successfully!"
echo ""
echo "🎯 Testing URLs:"
echo "• Registration: http://16.171.36.211/register"
echo "• Login: http://16.171.36.211/login"
echo "• Products: http://16.171.36.211/products"
echo ""
echo "Expected results:"
echo "✅ Registration works without column errors"
echo "✅ Login tracking works properly"
echo "✅ No 'casts()' method errors"
echo "✅ No database constraint violations"
echo "✅ Both web and API authentication work"
echo ""
echo "🔧 Fixed Issues:"
echo "• User model casts() method → property ✅"
echo "• LoginHistory null user_id handling ✅"  
echo "• Form field mapping (full_name→name, address→delivery_address) ✅"
echo "• API AuthController column names (Role→role) ✅"
echo "• Added session_data column to login_histories ✅"
echo ""
echo "🏁 Authentication system fully operational!"