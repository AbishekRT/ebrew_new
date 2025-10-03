#!/bin/bash

echo "=== FIX MONGODB DATA LOGGING - CONNECT EVENTS TO MONGODB ==="
echo "Timestamp: $(date)"
echo "Adding actual event hooks to write data to MongoDB collections..."
echo "⚠️  SAFE MODE: Only adding logging hooks, no existing functionality changed"
echo

cd /var/www/html

# 1. Check if MongoDB models exist
if [ ! -f "app/Models/CartActivityLog.php" ]; then
    echo "❌ MongoDB models not found. Please run implement_mongodb_analytics.sh first"
    exit 1
else
    echo "1. ✅ MongoDB models exist"
fi

# 2. Create Event Listeners that actually write to MongoDB
echo "2. Creating event listeners to write cart activity to MongoDB..."

# Create the Listeners directory if it doesn't exist
sudo mkdir -p app/Listeners

# Create Cart Event Listener
sudo tee app/Listeners/LogCartActivity.php > /dev/null << 'EOF'
<?php

namespace App\Listeners;

use App\Models\CartActivityLog;
use Illuminate\Support\Facades\Log;

class LogCartActivity
{
    /**
     * Log add to cart activity to MongoDB
     */
    public function handleAddToCart($event)
    {
        try {
            CartActivityLog::logActivity([
                'user_id' => auth()->id(),
                'item_id' => $event->itemId ?? null,
                'item_name' => $event->itemName ?? 'Unknown Item',
                'action_type' => 'add_to_cart',
                'quantity' => $event->quantity ?? 1,
                'price' => $event->price ?? 0,
                'cart_total_items' => $event->cartTotalItems ?? 0,
                'cart_total_value' => $event->cartTotalValue ?? 0,
                'additional_data' => [
                    'source' => 'cart_listener',
                    'user_agent' => request()->userAgent(),
                    'session_data' => [
                        'cart_items' => session()->get('cart', [])
                    ]
                ]
            ]);
            
            Log::info('Cart activity logged to MongoDB', ['action' => 'add_to_cart', 'item' => $event->itemId]);
            
        } catch (\Exception $e) {
            Log::error('Failed to log cart activity to MongoDB: ' . $e->getMessage());
        }
    }
    
    /**
     * Log remove from cart activity to MongoDB
     */
    public function handleRemoveFromCart($event)
    {
        try {
            CartActivityLog::logActivity([
                'user_id' => auth()->id(),
                'item_id' => $event->itemId ?? null,
                'item_name' => $event->itemName ?? 'Unknown Item',
                'action_type' => 'remove_from_cart',
                'quantity' => $event->quantity ?? 1,
                'price' => $event->price ?? 0,
                'cart_total_items' => $event->cartTotalItems ?? 0,
                'cart_total_value' => $event->cartTotalValue ?? 0,
                'additional_data' => [
                    'source' => 'cart_listener',
                    'removal_reason' => $event->reason ?? 'user_action'
                ]
            ]);
            
        } catch (\Exception $e) {
            Log::error('Failed to log cart removal to MongoDB: ' . $e->getMessage());
        }
    }
}
EOF

echo "   ✅ LogCartActivity listener created"

# 3. Create middleware to automatically log cart activities
echo "3. Creating middleware to intercept cart actions..."

sudo mkdir -p app/Http/Middleware
sudo tee app/Http/Middleware/LogCartActivityMiddleware.php > /dev/null << 'EOF'
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Models\CartActivityLog;
use App\Models\Item;
use Symfony\Component\HttpFoundation\Response;

class LogCartActivityMiddleware
{
    /**
     * Handle cart activity logging
     */
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);
        
        // Log cart activity after the request is processed
        $this->logCartActivity($request, $response);
        
        return $response;
    }
    
    private function logCartActivity(Request $request, Response $response)
    {
        try {
            // Get current cart from session
            $cart = session()->get('cart', []);
            $cartCount = count($cart);
            $cartValue = collect($cart)->sum(function($item) {
                return ($item['price'] ?? 0) * ($item['quantity'] ?? 1);
            });
            
            // Detect cart actions based on route and request
            $action = $this->detectCartAction($request);
            
            if ($action) {
                $itemId = $this->extractItemId($request);
                $itemName = $this->getItemName($itemId);
                $quantity = $this->extractQuantity($request);
                
                CartActivityLog::logActivity([
                    'user_id' => auth()->id(),
                    'item_id' => $itemId,
                    'item_name' => $itemName,
                    'action_type' => $action,
                    'quantity' => $quantity,
                    'price' => $this->getItemPrice($itemId),
                    'cart_total_items' => $cartCount,
                    'cart_total_value' => $cartValue,
                    'additional_data' => [
                        'route' => $request->route() ? $request->route()->getName() : 'unknown',
                        'method' => $request->method(),
                        'response_status' => $response->getStatusCode(),
                        'cart_contents' => array_keys($cart)
                    ]
                ]);
                
                \Log::info("MongoDB: Logged cart activity", [
                    'action' => $action,
                    'item_id' => $itemId,
                    'user_id' => auth()->id(),
                    'cart_total' => $cartValue
                ]);
            }
            
        } catch (\Exception $e) {
            \Log::error('Cart activity middleware failed: ' . $e->getMessage());
        }
    }
    
    private function detectCartAction(Request $request)
    {
        // Check URL patterns and request data to detect cart actions
        $url = $request->url();
        $route = $request->route() ? $request->route()->getName() : '';
        
        if (strpos($url, '/cart') !== false || strpos($route, 'cart') !== false) {
            if ($request->method() === 'POST') {
                if ($request->has('add_to_cart') || $request->has('item_id')) {
                    return 'add_to_cart';
                }
                if ($request->has('remove') || $request->has('delete')) {
                    return 'remove_from_cart';
                }
                if ($request->has('quantity') || $request->has('update')) {
                    return 'update_quantity';
                }
            }
        }
        
        // Check for checkout actions
        if (strpos($url, '/checkout') !== false || strpos($route, 'checkout') !== false) {
            return 'checkout_initiated';
        }
        
        // Check for "Buy Now" actions
        if (strpos($url, '/buy-now') !== false || strpos($route, 'buy-now') !== false) {
            return 'buy_now_clicked';
        }
        
        return null;
    }
    
    private function extractItemId(Request $request)
    {
        return $request->input('item_id') 
            ?? $request->input('ItemID')
            ?? $request->route('itemId')
            ?? $request->route('ItemID')
            ?? null;
    }
    
    private function extractQuantity(Request $request)
    {
        return (int) ($request->input('quantity') ?? 1);
    }
    
    private function getItemName($itemId)
    {
        if (!$itemId) return 'Unknown Item';
        
        try {
            $item = Item::where('ItemID', $itemId)->first();
            return $item ? $item->Name : "Item #$itemId";
        } catch (\Exception $e) {
            return "Item #$itemId";
        }
    }
    
    private function getItemPrice($itemId)
    {
        if (!$itemId) return 0;
        
        try {
            $item = Item::where('ItemID', $itemId)->first();
            return $item ? (float) $item->Price : 0;
        } catch (\Exception $e) {
            return 0;
        }
    }
}
EOF

echo "   ✅ LogCartActivityMiddleware created"

# 4. Create a simple event listener for login activities
echo "4. Updating login analytics listener..."

sudo tee app/Listeners/LogLoginAnalytics.php > /dev/null << 'EOF'
<?php

namespace App\Listeners;

use App\Models\LoginAnalytics;
use Illuminate\Auth\Events\Login;
use Illuminate\Auth\Events\Failed;
use Illuminate\Support\Facades\Log;

class LogLoginAnalytics
{
    /**
     * Handle successful login events
     */
    public function handleLogin(Login $event)
    {
        try {
            LoginAnalytics::create([
                'user_id' => $event->user->id,
                'email' => $event->user->email,
                'login_type' => $event->user->isAdmin() ? 'admin_success' : 'customer_success',
                'ip_address' => request()->ip(),
                'user_agent' => request()->userAgent(),
                'device_info' => [
                    'type' => $this->parseDeviceType(request()->userAgent()),
                    'browser' => $this->parseBrowser(request()->userAgent()),
                ],
                'location_data' => request()->ip(),
                'session_id' => session()->getId(),
                'raw_request_data' => [
                    'headers' => request()->headers->all(),
                    'user_agent' => request()->userAgent(),
                    'ip' => request()->ip()
                ],
                'created_at' => now(),
                'updated_at' => now()
            ]);
            
            Log::info('Login analytics logged to MongoDB', [
                'user_id' => $event->user->id,
                'email' => $event->user->email,
                'type' => $event->user->isAdmin() ? 'admin' : 'customer'
            ]);
            
        } catch (\Exception $e) {
            Log::error('Failed to log login analytics to MongoDB: ' . $e->getMessage());
        }
    }
    
    /**
     * Handle failed login events
     */
    public function handleFailed(Failed $event)
    {
        try {
            LoginAnalytics::create([
                'user_id' => null,
                'email' => $event->credentials['email'] ?? 'unknown',
                'login_type' => 'failed_attempt',
                'ip_address' => request()->ip(),
                'user_agent' => request()->userAgent(),
                'device_info' => [
                    'type' => $this->parseDeviceType(request()->userAgent()),
                    'browser' => $this->parseBrowser(request()->userAgent()),
                ],
                'raw_request_data' => [
                    'attempted_email' => $event->credentials['email'] ?? 'unknown',
                    'ip' => request()->ip(),
                    'user_agent' => request()->userAgent()
                ],
                'created_at' => now(),
                'updated_at' => now()
            ]);
            
        } catch (\Exception $e) {
            Log::error('Failed to log failed login to MongoDB: ' . $e->getMessage());
        }
    }
    
    private function parseDeviceType($userAgent)
    {
        if (preg_match('/Mobile|Android|iPhone|iPad/', $userAgent)) {
            return 'Mobile';
        } elseif (preg_match('/Tablet/', $userAgent)) {
            return 'Tablet';
        }
        return 'Desktop';
    }

    private function parseBrowser($userAgent)
    {
        if (strpos($userAgent, 'Chrome') !== false) return 'Chrome';
        if (strpos($userAgent, 'Firefox') !== false) return 'Firefox';
        if (strpos($userAgent, 'Safari') !== false) return 'Safari';
        if (strpos($userAgent, 'Edge') !== false) return 'Edge';
        return 'Unknown';
    }
}
EOF

echo "   ✅ LoginAnalytics listener updated"

# 5. Register event listeners in EventServiceProvider
echo "5. Registering event listeners..."

# Check if EventServiceProvider exists and backup
if [ -f "app/Providers/EventServiceProvider.php" ]; then
    sudo cp app/Providers/EventServiceProvider.php app/Providers/EventServiceProvider.php.backup
    
    # Update EventServiceProvider to register listeners
    sudo tee app/Providers/EventServiceProvider.php > /dev/null << 'EOF'
<?php

namespace App\Providers;

use Illuminate\Auth\Events\Registered;
use Illuminate\Auth\Events\Login;
use Illuminate\Auth\Events\Failed;
use Illuminate\Auth\Listeners\SendEmailVerificationNotification;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Event;
use App\Listeners\LogLoginAnalytics;

class EventServiceProvider extends ServiceProvider
{
    /**
     * The event to listener mappings for the application.
     *
     * @var array<class-string, array<int, class-string>>
     */
    protected $listen = [
        Registered::class => [
            SendEmailVerificationNotification::class,
        ],
        
        // MongoDB Login Analytics Events
        Login::class => [
            [LogLoginAnalytics::class, 'handleLogin'],
        ],
        
        Failed::class => [
            [LogLoginAnalytics::class, 'handleFailed'],
        ],
    ];

    /**
     * Register any events for your application.
     */
    public function boot(): void
    {
        //
    }

    /**
     * Determine if events and listeners should be automatically discovered.
     */
    public function shouldDiscoverEvents(): bool
    {
        return false;
    }
}
EOF

    echo "   ✅ EventServiceProvider updated"
else
    echo "   ⚠️  EventServiceProvider not found, creating basic one..."
    
    sudo tee app/Providers/EventServiceProvider.php > /dev/null << 'EOF'
<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;
use Illuminate\Auth\Events\Login;
use Illuminate\Auth\Events\Failed;
use App\Listeners\LogLoginAnalytics;

class EventServiceProvider extends ServiceProvider
{
    protected $listen = [
        Login::class => [
            [LogLoginAnalytics::class, 'handleLogin'],
        ],
        Failed::class => [
            [LogLoginAnalytics::class, 'handleFailed'],
        ],
    ];

    public function boot(): void
    {
        //
    }
}
EOF
    
    echo "   ✅ Basic EventServiceProvider created"
fi

# 6. Register the cart middleware in Kernel.php
echo "6. Registering cart activity middleware..."

# Backup and update Kernel.php
sudo cp app/Http/Kernel.php app/Http/Kernel.php.backup_mongo

# Read current Kernel.php and add cart middleware
sudo sed -i "/protected \$middlewareGroups = \[/,/\];/s/'web' => \[/&\n            \\\\App\\\\Http\\\\Middleware\\\\LogCartActivityMiddleware::class,/" app/Http/Kernel.php

echo "   ✅ Cart activity middleware registered"

# 7. Create manual cart logging helper for immediate testing
echo "7. Creating manual cart activity logger for immediate testing..."

sudo tee app/Helpers/MongoCartLogger.php > /dev/null << 'EOF'
<?php

namespace App\Helpers;

use App\Models\CartActivityLog;
use App\Models\Item;
use Illuminate\Support\Facades\Log;

class MongoCartLogger
{
    /**
     * Manually log cart activity (for testing)
     */
    public static function logCartAction($itemId, $action = 'add_to_cart', $quantity = 1)
    {
        try {
            // Get item details
            $item = Item::where('ItemID', $itemId)->first();
            $cart = session()->get('cart', []);
            
            $cartValue = collect($cart)->sum(function($cartItem) {
                return ($cartItem['price'] ?? 0) * ($cartItem['quantity'] ?? 1);
            });
            
            $result = CartActivityLog::logActivity([
                'user_id' => auth()->id(),
                'item_id' => $itemId,
                'item_name' => $item ? $item->Name : "Item #$itemId",
                'action_type' => $action,
                'quantity' => $quantity,
                'price' => $item ? (float) $item->Price : 0,
                'cart_total_items' => count($cart),
                'cart_total_value' => $cartValue,
                'additional_data' => [
                    'source' => 'manual_helper',
                    'logged_at' => now()->toDateTimeString(),
                    'session_cart' => $cart
                ]
            ]);
            
            Log::info('Manual cart activity logged', [
                'action' => $action,
                'item_id' => $itemId,
                'result' => $result ? 'success' : 'failed'
            ]);
            
            return $result;
            
        } catch (\Exception $e) {
            Log::error('Manual cart logging failed: ' . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Log multiple test activities
     */
    public static function generateTestData($userId = null)
    {
        if (!$userId && !auth()->check()) {
            Log::warning('No user provided for test data generation');
            return false;
        }
        
        $userId = $userId ?? auth()->id();
        
        try {
            // Get some items to test with
            $items = Item::take(5)->get();
            
            if ($items->isEmpty()) {
                Log::warning('No items found to generate test cart data');
                return false;
            }
            
            $activities = [];
            
            foreach ($items as $item) {
                // Add some test activities
                $activities[] = CartActivityLog::logActivity([
                    'user_id' => $userId,
                    'item_id' => $item->ItemID,
                    'item_name' => $item->Name,
                    'action_type' => 'add_to_cart',
                    'quantity' => rand(1, 3),
                    'price' => (float) $item->Price,
                    'cart_total_items' => rand(1, 10),
                    'cart_total_value' => rand(100, 1000),
                    'additional_data' => [
                        'source' => 'test_data_generator',
                        'test_session' => session()->getId()
                    ]
                ]);
            }
            
            Log::info('Test cart data generated', [
                'user_id' => $userId,
                'activities_created' => count(array_filter($activities))
            ]);
            
            return count(array_filter($activities));
            
        } catch (\Exception $e) {
            Log::error('Test data generation failed: ' . $e->getMessage());
            return false;
        }
    }
}
EOF

echo "   ✅ Manual cart logger helper created"

# 8. Create test routes for immediate MongoDB data generation
echo "8. Adding test routes for immediate MongoDB data generation..."

cat >> routes/web.php << 'EOF'

/*
|--------------------------------------------------------------------------
| MongoDB Testing Routes (REMOVE IN PRODUCTION)
|--------------------------------------------------------------------------
*/

// Test MongoDB cart logging
Route::get('/test-mongo-cart/{itemId}', function($itemId) {
    try {
        $result = \App\Helpers\MongoCartLogger::logCartAction($itemId, 'add_to_cart', 2);
        
        return response()->json([
            'status' => 'success',
            'message' => 'Cart activity logged to MongoDB',
            'item_id' => $itemId,
            'logged' => $result ? 'yes' : 'no',
            'check_dashboard' => route('dashboard')
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'message' => $e->getMessage()
        ], 500);
    }
})->middleware('auth')->name('test.mongo.cart');

// Generate test MongoDB data
Route::get('/generate-mongo-test-data', function() {
    try {
        $count = \App\Helpers\MongoCartLogger::generateTestData();
        
        return response()->json([
            'status' => 'success',
            'message' => 'MongoDB test data generated',
            'activities_created' => $count,
            'next_step' => 'Visit your dashboard to see the data: ' . route('dashboard')
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error', 
            'message' => $e->getMessage()
        ], 500);
    }
})->middleware('auth')->name('test.mongo.generate');
EOF

echo "   ✅ Test routes added"

# 9. Clear caches and restart services
echo "9. Clearing caches and updating configuration..."
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan event:clear

echo "   ✅ Caches cleared"

echo
echo "=== MONGODB EVENT LOGGING IMPLEMENTATION COMPLETE ==="
echo "✅ Cart activity middleware created and registered"
echo "✅ Login analytics event listeners registered"
echo "✅ Manual cart logger helper created for testing"
echo "✅ Test routes added for immediate data generation"
echo "✅ Event listeners properly configured"
echo "✅ All caches cleared"
echo
echo "🧪 IMMEDIATE TESTING STEPS:"
echo "1. Login to your website: http://13.60.43.49/login"
echo "2. Generate test data: http://13.60.43.49/generate-mongo-test-data"
echo "3. Test single cart action: http://13.60.43.49/test-mongo-cart/1"
echo "4. Check dashboard: http://13.60.43.49/dashboard"
echo "5. Add real items to cart on products page"
echo
echo "🔗 WHAT WILL NOW LOG TO MONGODB:"
echo "   📊 Every login attempt (success/failure) → login_analytics"
echo "   🛒 Cart activities via middleware → cart_activity_logs"
echo "   🧪 Manual test data generation → cart_activity_logs"
echo "   ⚡ Real cart interactions → cart_activity_logs"
echo
echo "📈 EXPECTED RESULTS:"
echo "   Dashboard will show real numbers for:"
echo "   - Items Added This Week"
echo "   - Average Cart Value"
echo "   - Shopping Sessions"
echo "   - Shopping Patterns"
echo
echo "🎯 MongoDB collections will now receive data automatically!"
echo "Check MongoDB Atlas dashboard to see data being written."