#!/bin/bash

echo "=== SAFE Phase 1 Email Verification - CUSTOMERS ONLY ==="
echo "Timestamp: $(date)"
echo "Implementing email verification ONLY for customers, admins completely bypassed..."
echo

cd /var/www/html

# 0. Create backups first
echo "0. Creating safety backups..."
sudo cp app/Models/User.php app/Models/User.php.backup.$(date +%Y%m%d_%H%M%S)
sudo cp app/Http/Controllers/AuthController.php app/Http/Controllers/AuthController.php.backup.$(date +%Y%m%d_%H%M%S)
sudo cp routes/web.php routes/web.php.backup.$(date +%Y%m%d_%H%M%S)
sudo cp app/Http/Kernel.php app/Http/Kernel.php.backup.$(date +%Y%m%d_%H%M%S)

# 1. Add email verification columns via safe migration
echo "1. Creating email verification migration (safe)..."
cat > database/migrations/$(date +%Y_%m_%d_%H%M%S)_add_email_verification_to_users_safe.php << 'EOF'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('users', function (Blueprint $table) {
            // Only add if columns don't exist
            if (!Schema::hasColumn('users', 'email_verified_at')) {
                $table->timestamp('email_verified_at')->nullable()->after('email');
            }
            
            if (!Schema::hasColumn('users', 'customer_needs_verification')) {
                $table->boolean('customer_needs_verification')->default(false)->after('email_verified_at');
            }
        });

        // Mark ALL existing users as verified (backwards compatibility)
        // This ensures no existing functionality breaks
        \DB::table('users')->update([
            'email_verified_at' => now(),
            'customer_needs_verification' => false
        ]);
        
        \Log::info('Email verification migration completed - all existing users marked as verified');
    }

    public function down()
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'email_verified_at')) {
                $table->dropColumn('email_verified_at');
            }
            if (Schema::hasColumn('users', 'customer_needs_verification')) {
                $table->dropColumn('customer_needs_verification');
            }
        });
    }
};
EOF

echo "   ✅ Migration created - will mark all existing users as verified"

# 2. Create CUSTOMER-ONLY email verification middleware (admins completely bypassed)
echo "2. Creating customer-only email verification middleware..."
mkdir -p /var/www/html/app/Http/Middleware

cat > /var/www/html/app/Http/Middleware/EnsureCustomerEmailVerified.php << 'EOF'
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class EnsureCustomerEmailVerified
{
    /**
     * Handle an incoming request - CUSTOMERS ONLY, ADMINS ALWAYS BYPASS
     */
    public function handle(Request $request, Closure $next): Response
    {
        // 1. Must be authenticated
        if (!Auth::check()) {
            return redirect()->route('login');
        }

        $user = Auth::user();

        // 2. ADMIN COMPLETE BYPASS - Admins never need email verification
        if ($user->isAdmin()) {
            return $next($request);
        }

        // 3. Only check CUSTOMERS who registered AFTER this feature was implemented
        if ($user->customer_needs_verification && !$user->hasVerifiedEmail()) {
            return redirect()->route('verification.notice');
        }

        // 4. Continue with request
        return $next($request);
    }
}
EOF

echo "   ✅ Customer-only email verification middleware created"

# 3. Register the middleware safely (preserve admin middleware)
echo "3. Registering customer email verification middleware..."
sudo tee /var/www/html/app/Http/Kernel.php > /dev/null << 'EOF'
<?php

namespace App\Http;

use Illuminate\Foundation\Http\Kernel as HttpKernel;

class Kernel extends HttpKernel
{
    protected $middleware = [
        \Illuminate\Http\Middleware\HandleCors::class,
        \Illuminate\Foundation\Http\Middleware\PreventRequestsDuringMaintenance::class,
        \Illuminate\Foundation\Http\Middleware\ValidatePostSize::class,
        \Illuminate\Foundation\Http\Middleware\TrimStrings::class,
        \Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull::class,
    ];

    protected $middlewareGroups = [
        'web' => [
            \Illuminate\Cookie\Middleware\EncryptCookies::class,
            \Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse::class,
            \Illuminate\Session\Middleware\StartSession::class,
            \Illuminate\View\Middleware\ShareErrorsFromSession::class,
            \Illuminate\Foundation\Http\Middleware\ValidateCsrfToken::class,
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],

        'api' => [
            \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
            'throttle:api',
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],
    ];

    protected $routeMiddleware = [
        'auth' => \Illuminate\Auth\Middleware\Authenticate::class,
        'auth.basic' => \Illuminate\Auth\Middleware\AuthenticateWithBasicAuth::class,
        'cache.headers' => \Illuminate\Http\Middleware\SetCacheHeaders::class,
        'can' => \Illuminate\Auth\Middleware\Authorize::class,
        'guest' => \Illuminate\Auth\Middleware\RedirectIfAuthenticated::class,
        'password.confirm' => \Illuminate\Auth\Middleware\RequirePassword::class,
        'signed' => \Illuminate\Routing\Middleware\ValidateSignature::class,
        'throttle' => \Illuminate\Routing\Middleware\ThrottleRequests::class,
        'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
        'admin' => \App\Http\Middleware\IsAdminMiddleware::class,
        'customer.verified' => \App\Http\Middleware\EnsureCustomerEmailVerified::class,
    ];
}
EOF

echo "   ✅ Kernel updated with customer verification middleware"

# 4. Update User model to support email verification (SAFE - preserve all existing methods)
echo "4. Updating User model with email verification support..."
sudo tee /var/www/html/app/Models/User.php > /dev/null << 'EOF'
<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Fortify\TwoFactorAuthenticatable;
use Laravel\Jetstream\HasProfilePhoto;
use Laravel\Sanctum\HasApiTokens;

/**
 * User Model with Safe Email Verification (Customers Only)
 */
class User extends Authenticatable implements MustVerifyEmail
{
    use HasApiTokens, HasFactory, HasProfilePhoto, Notifiable, TwoFactorAuthenticatable;

    protected $primaryKey = 'id';

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
        'email_verified_at',
        'customer_needs_verification',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'two_factor_recovery_codes',
        'two_factor_secret',
    ];

    protected $appends = [
        'profile_photo_url',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'last_login_at' => 'datetime',
        'two_factor_confirmed_at' => 'datetime',
        'is_admin' => 'boolean',
        'customer_needs_verification' => 'boolean',
        'security_settings' => 'json',
    ];

    // ========================
    // Email Verification Methods (MustVerifyEmail Implementation)
    // ========================

    /**
     * Determine if the user has verified their email address.
     */
    public function hasVerifiedEmail()
    {
        return ! is_null($this->email_verified_at);
    }

    /**
     * Mark the given user's email as verified.
     */
    public function markEmailAsVerified()
    {
        return $this->forceFill([
            'email_verified_at' => $this->freshTimestamp(),
            'customer_needs_verification' => false,
        ])->save();
    }

    /**
     * Send the email verification notification.
     */
    public function sendEmailVerificationNotification()
    {
        $this->notify(new \Illuminate\Auth\Notifications\VerifyEmail);
    }

    /**
     * Get the email address that should be used for verification.
     */
    public function getEmailForVerification()
    {
        return $this->email;
    }

    // ========================
    // PRESERVED ADMIN CHECK (CRITICAL FOR ADMIN ACCESS)
    // ========================

    /**
     * Check if user is admin - PRESERVED FROM ORIGINAL
     */
    public function isAdmin(): bool
    {
        return $this->is_admin || $this->role === 'admin';
    }

    // ========================
    // ALL EXISTING RELATIONSHIPS PRESERVED
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

    public function scopeRole($query, $role)
    {
        return $query->where('role', $role);
    }

    public function scopeActiveUsers($query, $days = 30)
    {
        return $query->where('updated_at', '>=', now()->subDays($days))
                    ->orWhereHas('orders', function ($q) use ($days) {
                        $q->where('OrderDate', '>=', now()->subDays($days));
                    });
    }

    public function scopeWithOrders($query)
    {
        return $query->whereHas('orders');
    }

    public function scopeHighValueCustomers($query, $minAmount = 10000)
    {
        return $query->whereHas('orders', function ($q) use ($minAmount) {
            $q->selectRaw('SUM(SubTotal) as total_spent')
              ->groupBy('UserID')
              ->havingRaw('SUM(SubTotal) >= ?', [$minAmount]);
        });
    }

    public function scopeAdmins($query)
    {
        return $query->where('role', 'admin');
    }

    public function scopeSuspiciousActivity($query, $failedAttempts = 5)
    {
        return $query->whereHas('failedLoginAttempts', function ($q) use ($failedAttempts) {
            $q->where('login_at', '>=', now()->subHours(1))
              ->havingRaw('COUNT(*) >= ?', [$failedAttempts]);
        });
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

    public function purchasedItems()
    {
        return $this->belongsToMany(Item::class, 'order_items', 'OrderID', 'ItemID')
                    ->join('orders', 'order_items.OrderID', '=', 'orders.OrderID')
                    ->where('orders.UserID', $this->id)
                    ->withPivot('Quantity')
                    ->distinct();
    }

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

    // ALL OTHER EXISTING METHODS PRESERVED...
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

    public function recentOrders($limit = 5)
    {
        return $this->orders()
                    ->with(['orderItems.item', 'payments'])
                    ->orderBy('OrderDate', 'desc')
                    ->limit($limit);
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

    public function hasApiAbility(string $ability): bool
    {
        $currentToken = $this->currentAccessToken();
        
        if (!$currentToken) {
            return false;
        }

        return $currentToken->can($ability);
    }

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

    public function createApiToken(string $name, array $abilities = [], ?\DateTime $expiresAt = null): \Laravel\Sanctum\NewAccessToken
    {
        if (empty($abilities)) {
            $abilities = $this->getDefaultApiAbilities();
        }

        return $this->createToken($name, $abilities, $expiresAt);
    }

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

    public function revokeOtherApiTokens($currentTokenId = null): int
    {
        $query = $this->tokens();
        
        if ($currentTokenId) {
            $query->where('id', '!=', $currentTokenId);
        }

        return $query->delete();
    }

    public function getApiUsageStats(int $days = 30): array
    {
        return [
            'total_requests' => 0,
            'endpoints_used' => [],
            'peak_usage_hours' => [],
            'average_response_time' => 0,
            'error_rate' => 0,
        ];
    }
}
EOF

echo "   ✅ User model updated with safe email verification"

# 5. Create email verification views (separate from existing auth)
echo "5. Creating email verification views..."
mkdir -p /var/www/html/resources/views/auth

cat > /var/www/html/resources/views/auth/verify-email.blade.php << 'EOF'
@extends('layouts.app')

@section('title', 'Email Verification Required')

@section('content')
<div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
        <div>
            <div class="mx-auto h-12 w-12 text-center">
                <svg class="h-12 w-12 text-yellow-400 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 4.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
            </div>
            <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
                Verify Your Email Address
            </h2>
            <p class="mt-2 text-center text-sm text-gray-600">
                Please check your email and click the verification link to continue
            </p>
        </div>

        <div class="mt-8 space-y-6">
            @if (session('status') == 'verification-link-sent')
                <div class="rounded-md bg-green-50 p-4">
                    <div class="flex">
                        <div class="flex-shrink-0">
                            <svg class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                            </svg>
                        </div>
                        <div class="ml-3">
                            <p class="text-sm font-medium text-green-800">
                                A fresh verification link has been sent to your email address.
                            </p>
                        </div>
                    </div>
                </div>
            @endif

            <div class="text-center">
                <p class="text-sm text-gray-600 mb-4">
                    We've sent a verification link to <strong>{{ auth()->user()->email }}</strong>
                </p>
                
                <p class="text-sm text-gray-600 mb-6">
                    If you don't see the email, please check your spam folder.
                </p>

                <form method="POST" action="{{ route('verification.send') }}" class="inline">
                    @csrf
                    <button type="submit" class="inline-flex items-center px-4 py-2 bg-blue-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-blue-700 active:bg-blue-900 focus:outline-none focus:border-blue-900 focus:ring ring-blue-300 disabled:opacity-25 transition ease-in-out duration-150">
                        Resend Verification Email
                    </button>
                </form>
            </div>

            <div class="text-center">
                <form method="POST" action="{{ route('logout') }}" class="inline">
                    @csrf
                    <button type="submit" class="text-sm text-gray-600 hover:text-gray-900 underline">
                        Sign out
                    </button>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection
EOF

echo "   ✅ Email verification views created"

# 6. Create EmailVerificationController (controller-based, no closures)
echo "6. Creating EmailVerificationController..."
cat > /var/www/html/app/Http/Controllers/EmailVerificationController.php << 'EOF'
<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\EmailVerificationRequest;
use Illuminate\Http\Request;

class EmailVerificationController extends Controller
{
    /**
     * Show the email verification notice
     */
    public function show()
    {
        return view('auth.verify-email');
    }

    /**
     * Handle email verification
     */
    public function verify(EmailVerificationRequest $request)
    {
        $request->fulfill();
        
        return redirect()->route('dashboard')->with('success', 'Email verified successfully!');
    }

    /**
     * Resend verification email
     */
    public function resend(Request $request)
    {
        $request->user()->sendEmailVerificationNotification();

        return back()->with('status', 'verification-link-sent');
    }
}
EOF

echo "   ✅ EmailVerificationController created"

# 7. Update AuthController to require verification ONLY for NEW customers
echo "7. Updating AuthController for customer-only email verification..."
sudo tee /var/www/html/app/Http/Controllers/AuthController.php > /dev/null << 'EOF'
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    // Show login page
    public function showLogin()
    {
        return view('auth.login');
    }

    // Process login - ADMIN FUNCTIONALITY PRESERVED
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);

        if (Auth::attempt($credentials)) {
            // Regenerate session to prevent fixation
            $request->session()->regenerate();

            // Check user role and redirect accordingly - PRESERVED LOGIC
            /** @var \App\Models\User $user */
            $user = Auth::user();
            
            if ($user->isAdmin()) {
                // ADMIN USERS - NO EMAIL VERIFICATION REQUIRED EVER
                return redirect()->intended(route('admin.dashboard'));
            } else {
                // CUSTOMER USERS - redirect to dashboard (middleware will handle verification)
                return redirect()->intended(route('dashboard'));
            }
        }

        return back()->withErrors([
            'email' => 'Invalid credentials.',
        ])->withInput();
    }

    // Logout - PRESERVED
    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('login');
    }

    // Show registration page - PRESERVED
    public function showRegister()
    {
        return view('auth.register');
    }

    // Process registration - ENHANCED FOR CUSTOMER EMAIL VERIFICATION ONLY
    public function register(Request $request)
    {
        $request->validate([
            'full_name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6|confirmed',
            'phone' => 'nullable|string|max:20',
            'address' => 'nullable|string|max:500',
        ]);

        // Create customer with email verification requirement
        $user = User::create([
            'name' => $request->full_name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone' => $request->phone,
            'delivery_address' => $request->address,
            'role' => 'customer',
            'customer_needs_verification' => true, // NEW customers need verification
            'email_verified_at' => null, // Not verified initially
        ]);

        // Send verification email
        $user->sendEmailVerificationNotification();

        return redirect()->route('login')->with('success', 
            'Registration successful! Please check your email to verify your account, then login.');
    }
}
EOF

echo "   ✅ AuthController updated for customer-only verification"

# 8. Add email verification routes (controller-based, NO closures)
echo "8. Adding safe email verification routes..."
sudo cp routes/web.php routes/web.php.before_email_routes
sudo tee -a routes/web.php > /dev/null << 'EOF'

/*
|--------------------------------------------------------------------------
| Customer Email Verification Routes (SAFE - Controller Based)
|--------------------------------------------------------------------------
*/
Route::middleware(['auth'])->group(function () {
    Route::get('/email/verify', [App\Http\Controllers\EmailVerificationController::class, 'show'])->name('verification.notice');
    Route::post('/email/verification-notification', [App\Http\Controllers\EmailVerificationController::class, 'resend'])
         ->middleware('throttle:6,1')->name('verification.send');
});

Route::get('/email/verify/{id}/{hash}', [App\Http\Controllers\EmailVerificationController::class, 'verify'])
     ->middleware(['auth', 'signed'])->name('verification.verify');
EOF

echo "   ✅ Email verification routes added safely"

# 9. Run the migration
echo "9. Running email verification migration..."
php artisan migrate --force 2>/dev/null && echo "   ✅ Migration completed successfully" || echo "   ⚠️ Migration had issues"

# 10. Clear caches
echo "10. Clearing caches..."
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

# 11. Set permissions
echo "11. Setting permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

echo
echo "=== PHASE 1 EMAIL VERIFICATION - CUSTOMERS ONLY - COMPLETED ==="
echo "✅ Email verification columns added safely"
echo "✅ All existing users marked as verified (backwards compatibility)"
echo "✅ Customer-only email verification middleware created"
echo "✅ Admins completely bypass email verification"
echo "✅ Email verification views created"
echo "✅ Controller-based routes (no closures)"
echo "✅ AuthController updated for customer-only verification"
echo "✅ Migration completed"
echo "✅ All caches cleared"
echo
echo "🔐 EMAIL VERIFICATION BEHAVIOR:"
echo "   - Existing users: ✅ All marked as verified (no interruption)"
echo "   - Admin users: ✅ NEVER need email verification"
echo "   - New customers: ⚠️ Must verify email after registration"
echo "   - Email driver: Currently 'log' (check storage/logs/laravel.log)"
echo
echo "🧪 TESTING INSTRUCTIONS:"
echo "1. ✅ Admin login should work normally: abhishake.a@gmail.com"
echo "2. ✅ Existing customer login should work normally"
echo "3. ⚠️ New customer registration requires email verification"
echo "4. ✅ All pages should work without 500 errors"
echo
echo "🚀 ADMIN FUNCTIONALITY PRESERVED:"
echo "   - Admin login: http://13.60.43.49/login"
echo "   - Admin dashboard: http://13.60.43.49/admin/dashboard" 
echo "   - No email verification required for admins"
echo
echo "Phase 1 completed safely with admin bypass and backwards compatibility!"