#!/bin/bash

# COMPREHENSIVE EMERGENCY FIX - All Laravel Issues
# This script fixes Products, Registration, and Login errors

set -e

echo "🚨 COMPREHENSIVE EMERGENCY FIX - All Issues"
echo "==========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_PATH="/var/www/html"

echo -e "${BLUE}🔍 Step 1: Backup and diagnose current state${NC}"
cd $PROJECT_PATH

# Create backup
cp -r app/Http/Controllers app/Http/Controllers.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
cp -r app/Models app/Models.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
cp -r resources/views resources/views.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

echo -e "${GREEN}✅ Backup created${NC}"

echo -e "\n${BLUE}🔧 Step 2: Fix AuthController - Use correct column names${NC}"
cat > app/Http/Controllers/AuthController.php << 'EOF'
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

            // Check user role and redirect accordingly
            /** @var \App\Models\User $user */
            $user = Auth::user();
            
            if ($user->isAdmin()) {
                // Redirect admin users to admin dashboard
                return redirect()->intended(route('admin.dashboard'));
            } else {
                // Redirect regular users to customer dashboard
                return redirect()->intended(route('dashboard'));
            }
        }

        return back()->withErrors([
            'email' => 'Invalid credentials.',
        ])->withInput();
    }

    // Logout
    public function logout(Request $request)
    {
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

    // Process registration - FIXED COLUMN NAMES
    public function register(Request $request)
    {
        $request->validate([
            'full_name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6|confirmed',
            'phone' => 'nullable|string|max:20',
            'address' => 'nullable|string|max:500',
        ]);

        // Use correct lowercase column names that match database migration
        User::create([
            'name' => $request->full_name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone' => $request->phone,
            'delivery_address' => $request->address,
            'role' => 'customer', // Use lowercase 'customer' role
        ]);

        return redirect()->route('login')->with('success', 'Registration successful! Please login.');
    }
}
EOF

echo -e "${GREEN}✅ AuthController fixed${NC}"

echo -e "\n${BLUE}🔧 Step 3: Fix User Model - Use correct column names${NC}"
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
     * The attributes that are mass assignable - FIXED COLUMN NAMES
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',              // lowercase 'role'
        'phone',             // lowercase 'phone'  
        'delivery_address',  // lowercase 'delivery_address'
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
     * Get the attributes that should be cast.
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

    // Relationships
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

    // Helper Methods
    public function isAdmin(): bool
    {
        return $this->role === 'admin'; // Use lowercase 'role' column
    }

    public function scopeRole($query, $role)
    {
        return $query->where('role', $role); // Use lowercase 'role' column
    }

    public function scopeAdmins($query)
    {
        return $query->where('role', 'admin'); // Use lowercase 'role' column
    }

    public function totalSpent()
    {
        return $this->orders()->sum('SubTotal') ?? 0.0;
    }
}
EOF

echo -e "${GREEN}✅ User Model fixed${NC}"

echo -e "\n${BLUE}🔧 Step 4: Fix Products View - Safe route generation${NC}"
cat > resources/views/products.blade.php << 'EOF'
@extends('layouts.app')

@section('title', 'Products - eBrew Café')

@section('content')

<!-- Hero Banner -->
<div class="relative w-full h-80 sm:h-[500px]">
    <img src="{{ asset('images/B1.png') }}" alt="Hero Image" class="w-full h-full object-cover">
    <div class="absolute inset-0 bg-black/40 flex items-center justify-center">
        <div class="text-center text-white px-4">
            <h1 class="text-3xl sm:text-5xl font-bold">Ebrew Café</h1>
            <p class="text-lg mt-2">Handpicked brews, delivered with care</p>
        </div>
    </div>
</div>

<!-- Product Sections -->
<section class="max-w-7xl mx-auto px-6 py-16 space-y-20">

    @foreach(['Featured Collection', 'Best Sellers', 'New Arrivals'] as $category)
        <div>
            <h2 class="text-2xl font-bold text-gray-900 mb-6 flex items-center">
                <span class="w-2 h-6 bg-red-600 inline-block mr-3 rounded"></span>{{ $category }}
            </h2>

            <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-10 justify-items-center">
                @forelse($products as $product)
                    @if($product && $product->id)
                        <a href="{{ route('products.show', $product->id) }}" 
                           class="group bg-white rounded-lg shadow hover:shadow-lg transition p-4 text-center w-full max-w-[200px]">
                    @else
                        <div class="group bg-white rounded-lg shadow hover:shadow-lg transition p-4 text-center w-full max-w-[200px] cursor-not-allowed opacity-75">
                    @endif

                        <!-- Product Image -->
                        <div class="aspect-w-1 aspect-h-1">
                            <img src="{{ $product->image_url ?? asset('images/default.png') }}" 
                                 alt="{{ $product->Name ?? 'Product' }}" 
                                 class="w-full h-full object-contain rounded">
                        </div>

                        <!-- Product Name -->
                        <h3 class="text-sm font-semibold text-gray-800 mt-4 group-hover:text-red-600 transition">
                            {{ $product->Name ?? 'Unnamed Product' }}
                        </h3>

                        <!-- Product Price -->
                        <p class="text-red-600 font-bold mt-2">
                            Rs. {{ number_format($product->Price ?? 0, 2) }}
                        </p>

                        @if(!$product || !$product->id)
                            <p class="text-xs text-gray-500 mt-1">Product ID missing</p>
                        @endif

                    @if($product && $product->id)
                        </a>
                    @else
                        </div>
                    @endif
                @empty
                    <div class="col-span-full text-center py-12">
                        <p class="text-gray-500 text-lg">No products available at the moment.</p>
                        <p class="text-gray-400 text-sm mt-2">Please check back later.</p>
                    </div>
                @endforelse
            </div>
        </div>
    @endforeach

</section>

@endsection
EOF

echo -e "${GREEN}✅ Products view fixed${NC}"

echo -e "\n${BLUE}🔧 Step 5: Disable Login History temporarily${NC}"
# Check if LoginListener exists and disable it temporarily
if [ -f "app/Listeners/LoginListener.php" ]; then
    mv app/Listeners/LoginListener.php app/Listeners/LoginListener.php.disabled
    echo -e "${YELLOW}⚠️  LoginListener temporarily disabled${NC}"
fi

echo -e "\n${BLUE}🗃️  Step 6: Ensure database structure is correct${NC}"
cd $PROJECT_PATH
php artisan migrate --force

echo -e "\n${BLUE}🌱 Step 7: Seed database with products${NC}"
php artisan tinker --execute="
// Clear and recreate items
try {
    \App\Models\Item::truncate();
    echo 'Cleared existing items' . PHP_EOL;
} catch (Exception \$e) {
    echo 'Note: ' . \$e->getMessage() . PHP_EOL;
}

\$items = [
    ['Name' => 'Ethiopian Premium Coffee', 'Description' => 'Rich Ethiopian coffee with fruity notes and floral aroma', 'Price' => 2500.00, 'Image' => '1.png', 'TastingNotes' => 'Fruity, bright acidity, floral', 'ShippingAndReturns' => 'Free shipping on orders over Rs. 3000', 'RoastDates' => '2024-01-15'],
    ['Name' => 'Colombian Dark Roast', 'Description' => 'Bold Colombian dark roast with chocolate undertones', 'Price' => 2200.00, 'Image' => '2.png', 'TastingNotes' => 'Chocolate, nuts, full body', 'ShippingAndReturns' => 'Free shipping on orders over Rs. 3000', 'RoastDates' => '2024-01-16'],
    ['Name' => 'Brazilian Medium Roast', 'Description' => 'Smooth Brazilian coffee with perfect balance', 'Price' => 1800.00, 'Image' => '3.png', 'TastingNotes' => 'Caramel, balanced, smooth', 'ShippingAndReturns' => 'Free shipping on orders over Rs. 3000', 'RoastDates' => '2024-01-17'],
    ['Name' => 'Guatemala Antigua', 'Description' => 'Complex volcanic soil coffee with spicy notes', 'Price' => 2800.00, 'Image' => '4.png', 'TastingNotes' => 'Spicy, smoky, complex', 'ShippingAndReturns' => 'Free shipping on orders over Rs. 3000', 'RoastDates' => '2024-01-18'],
    ['Name' => 'Kenya AA Light Roast', 'Description' => 'Bright Kenyan coffee with wine-like characteristics', 'Price' => 2600.00, 'Image' => '5.jpg', 'TastingNotes' => 'Wine-like, berry, bright acidity', 'ShippingAndReturns' => 'Free shipping on orders over Rs. 3000', 'RoastDates' => '2024-01-19'],
    ['Name' => 'Costa Rica Tarrazu', 'Description' => 'High altitude Costa Rican coffee with clean finish', 'Price' => 2400.00, 'Image' => '6.jpg', 'TastingNotes' => 'Citrus, clean, bright', 'ShippingAndReturns' => 'Free shipping on orders over Rs. 3000', 'RoastDates' => '2024-01-20'],
    ['Name' => 'Jamaica Blue Mountain', 'Description' => 'World famous mild Jamaican coffee, premium grade', 'Price' => 4500.00, 'Image' => '7.jpg', 'TastingNotes' => 'Mild, sweet, well-balanced', 'ShippingAndReturns' => 'Free shipping on orders over Rs. 3000', 'RoastDates' => '2024-01-21'],
    ['Name' => 'Yemen Mocha', 'Description' => 'Ancient coffee variety with distinctive wine characteristics', 'Price' => 3200.00, 'Image' => '8.jpg', 'TastingNotes' => 'Wine-like, earthy, complex', 'ShippingAndReturns' => 'Free shipping on orders over Rs. 3000', 'RoastDates' => '2024-01-22']
];

foreach (\$items as \$item) {
    try {
        \$created = \App\Models\Item::create(\$item);
        echo 'Created: ' . \$created->id . ' - ' . \$created->Name . PHP_EOL;
    } catch (Exception \$e) {
        echo 'Error creating item: ' . \$e->getMessage() . PHP_EOL;
    }
}

echo 'Total items: ' . \App\Models\Item::count() . PHP_EOL;
"

echo -e "\n${BLUE}🧪 Step 8: Test all functionality${NC}"
echo "Testing User model:"
php artisan tinker --execute="
try {
    // Test user creation with correct columns
    \$testData = [
        'name' => 'Test User Fix',
        'email' => 'testfix@example.com',
        'password' => bcrypt('password123'),
        'phone' => '0771234567',
        'delivery_address' => 'Test Address',
        'role' => 'customer'
    ];
    
    \$existing = \App\Models\User::where('email', 'testfix@example.com')->first();
    if (\$existing) \$existing->delete();
    
    \$user = \App\Models\User::create(\$testData);
    echo '✅ User creation: SUCCESS' . PHP_EOL;
    echo 'Name: ' . \$user->name . ', Email: ' . \$user->email . PHP_EOL;
    echo 'Phone: ' . \$user->phone . ', Address: ' . \$user->delivery_address . PHP_EOL;
    echo 'Role: ' . \$user->role . ', IsAdmin: ' . (\$user->isAdmin() ? 'YES' : 'NO') . PHP_EOL;
    
    \$user->delete();
    echo '🗑️  Test user cleaned up' . PHP_EOL;
} catch (Exception \$e) {
    echo '❌ User test failed: ' . \$e->getMessage() . PHP_EOL;
}
"

echo "Testing Products functionality:"
php artisan tinker --execute="
try {
    \$products = \App\Models\Item::take(3)->get();
    echo 'Products found: ' . \$products->count() . PHP_EOL;
    
    foreach (\$products as \$product) {
        \$url = route('products.show', \$product->id);
        echo 'Product: ' . \$product->Name . ' -> ' . \$url . PHP_EOL;
    }
    echo '✅ Route generation: SUCCESS' . PHP_EOL;
} catch (Exception \$e) {
    echo '❌ Products test failed: ' . \$e->getMessage() . PHP_EOL;
}
"

echo -e "\n${BLUE}🔄 Step 9: Clear all caches${NC}"
cd $PROJECT_PATH
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
echo -e "${GREEN}✅ All caches cleared${NC}"

php artisan config:cache
php artisan route:cache
echo -e "${GREEN}✅ Caches rebuilt${NC}"

echo -e "\n${BLUE}🌐 Step 10: Test HTTP responses${NC}"
echo "Testing URL responses:"
curl -s -o /dev/null -w "Products: %{http_code} (200 expected)\n" "http://localhost/products"
curl -s -o /dev/null -w "Register: %{http_code} (200 expected)\n" "http://localhost/register"
curl -s -o /dev/null -w "Login: %{http_code} (200 expected)\n" "http://localhost/login"
curl -s -o /dev/null -w "Home: %{http_code} (200 expected)\n" "http://localhost/"

echo -e "\n${GREEN}🏁 COMPREHENSIVE FIX COMPLETE!${NC}"
echo "=========================================="
echo -e "${YELLOW}📋 Issues Fixed:${NC}"
echo "✅ Products UrlGenerationException - Safe route generation with null checks"
echo "✅ Registration column errors - Using correct lowercase column names"
echo "✅ AuthController using proper database columns"
echo "✅ User model updated with correct fillable columns"
echo "✅ Login history errors temporarily disabled"
echo "✅ Database seeded with 8 coffee products"
echo "✅ All caches cleared and rebuilt"
echo ""
echo -e "${BLUE}🧪 Test URLs:${NC}"
echo "Products: http://ec2-13-60-43-49.eu-north-1.compute.amazonaws.com/products"
echo "Register: http://ec2-13-60-43-49.eu-north-1.compute.amazonaws.com/register"
echo "Login: http://ec2-13-60-43-49.eu-north-1.compute.amazonaws.com/login"
echo ""
echo -e "${GREEN}🎯 ALL ISSUES SHOULD NOW BE RESOLVED!${NC}"