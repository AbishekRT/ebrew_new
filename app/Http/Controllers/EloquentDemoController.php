<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Item;
use App\Models\Order;
use App\Models\Review;
use App\Services\OrderService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EloquentDemoController extends Controller
{
    protected $orderService;

    public function __construct(OrderService $orderService)
    {
        $this->orderService = $orderService;
    }

    /**
     * Demonstrate advanced scopes and query builder
     */
    public function advancedScopes()
    {
        $data = [];

        // 1. Advanced User Scopes
        $data['admin_users'] = User::role('admin')->get();
        $data['active_users'] = User::activeUsers(30)->get();
        $data['high_value_customers'] = User::highValueCustomers(5000)->get();
        $data['users_with_orders'] = User::withOrders()->withCount('orders')->get();

        // 2. Advanced Item Scopes with Custom Collection
        $items = Item::all(); // Returns ItemCollection
        $data['price_statistics'] = $items->getPriceStatistics();
        $data['items_by_price_range'] = $items->groupByPriceRange();
        $data['gift_recommendations'] = $items->getGiftRecommendations(3000);

        // 3. Complex Item Queries
        $data['popular_items'] = Item::popular(5)->get();
        $data['featured_items'] = Item::featured()->get();
        $data['search_results'] = Item::search('coffee')->priceRange(1000, 3000)->get();

        // 4. Advanced Order Scopes
        $data['recent_high_value_orders'] = Order::recent(30)->highValue(3000)->complete()->get();
        $data['paid_orders'] = Order::byPaymentStatus('paid')->get();

        return response()->json([
            'message' => 'Advanced Eloquent Scopes Demonstration',
            'data' => $data
        ]);
    }

    /**
     * Demonstrate polymorphic relationships
     */
    public function polymorphicRelationships()
    {
        $data = [];

        // 1. Create sample reviews (polymorphic)
        $item = Item::first();
        $order = Order::first();
        $user = User::first();

        if ($item && $user) {
            $itemReview = Review::create([
                'reviewable_id' => $item->ItemID,
                'reviewable_type' => Item::class,
                'user_id' => $user->id,
                'rating' => 5,
                'title' => 'Excellent Coffee!',
                'comment' => 'This coffee exceeded my expectations. Great flavor and aroma.',
                'is_featured' => true
            ]);
            $data['item_review_created'] = $itemReview;
        }

        if ($order && $user) {
            $orderReview = Review::create([
                'reviewable_id' => $order->OrderID,
                'reviewable_type' => Order::class,
                'user_id' => $user->id,
                'rating' => 4,
                'title' => 'Great Service',
                'comment' => 'Fast delivery and excellent customer service.',
                'is_featured' => false
            ]);
            $data['order_review_created'] = $orderReview;
        }

        // 2. Query polymorphic relationships
        $data['item_reviews'] = $item ? $item->reviews()->with('user')->get() : [];
        $data['order_reviews'] = $order ? $order->reviews()->with('user')->get() : [];
        $data['featured_reviews'] = Review::featured()->with(['reviewable', 'user'])->get();

        return response()->json([
            'message' => 'Polymorphic Relationships Demonstration',
            'data' => $data
        ]);
    }

    /**
     * Demonstrate advanced relationships and eager loading
     */
    public function advancedRelationships()
    {
        $data = [];

        // 1. Complex Many-to-Many with Pivot Data
        $orders = Order::with(['items' => function ($query) {
            $query->withPivot('Quantity');
        }])->limit(5)->get();
        $data['orders_with_items_and_quantity'] = $orders;

        // 2. Has-Many-Through Relationships
        $user = User::first();
        if ($user) {
            $data['user_payments_through_orders'] = $user->payments;
            $data['user_purchased_items'] = $user->purchasedItems;
            $data['user_favorite_items'] = $user->favoriteItems()->get();
        }

        // 3. Latest/Oldest Of Many
        $ordersWithLatestPayment = Order::with('latestPayment')->get();
        $data['orders_with_latest_payment'] = $ordersWithLatestPayment;

        // 4. Advanced Eager Loading with Constraints
        $itemsWithRecentReviews = Item::with(['reviews' => function ($query) {
            $query->recent(30)->highRated(4)->with('user');
        }])->get();
        $data['items_with_recent_high_reviews'] = $itemsWithRecentReviews;

        // 5. Counting Related Models
        $usersWithCounts = User::withCount(['orders', 'reviews'])
                              ->withSum('orders', 'SubTotal')
                              ->get();
        $data['users_with_statistics'] = $usersWithCounts;

        return response()->json([
            'message' => 'Advanced Relationships Demonstration',
            'data' => $data
        ]);
    }

    /**
     * Demonstrate advanced mutators, casts, and accessors
     */
    public function mutatorsCastsAccessors()
    {
        $data = [];

        // 1. Test Item Mutators and Accessors
        $item = Item::first();
        if ($item) {
            $data['item_original'] = [
                'name' => $item->Name,
                'price' => $item->Price
            ];
            
            $data['item_formatted'] = [
                'formatted_price' => $item->formatted_price,
                'price_in_usd' => $item->price_in_usd,
                'short_description' => $item->short_description,
                'is_premium' => $item->is_premium,
                'slug' => $item->slug,
                'image_url' => $item->image_url
            ];
        }

        // 2. Test Order Accessors
        $order = Order::first();
        if ($order) {
            $data['order_formatted'] = [
                'formatted_subtotal' => $order->formatted_sub_total,
                'status' => $order->status,
                'total_items' => $order->total_items,
                'is_recent' => $order->is_recent
            ];
        }

        // 3. Test Review Accessors
        $review = Review::first();
        if ($review) {
            $data['review_formatted'] = [
                'stars' => $review->stars,
                'is_recent' => $review->is_recent,
                'short_comment' => $review->short_comment
            ];
        }

        // 4. Test Casting
        $data['casting_demo'] = [
            'item_price_cast' => $item ? gettype($item->Price) : 'N/A',
            'order_date_cast' => $order ? get_class($order->OrderDate) : 'N/A'
        ];

        return response()->json([
            'message' => 'Mutators, Casts, and Accessors Demonstration',
            'data' => $data
        ]);
    }

    /**
     * Demonstrate service layer with transactions
     */
    public function serviceLayerDemo()
    {
        $data = [];

        try {
            // 1. Advanced Statistics
            $data['order_statistics'] = $this->orderService->getOrderStatistics([
                'date_from' => now()->subDays(30),
                'min_amount' => 1000
            ]);

            // 2. Top Customers Analysis
            $data['top_customers'] = $this->orderService->getTopCustomers(5);

            // 3. Popular Items Analysis
            $data['popular_items'] = $this->orderService->getPopularItems(5, 30);

            // 4. Sales Report with Caching
            $data['sales_report'] = $this->orderService->generateSalesReport(
                now()->subDays(30),
                now()
            );

            $data['success'] = true;
            $data['message'] = 'Service layer with advanced Eloquent features demonstrated successfully';

        } catch (\Exception $e) {
            $data['success'] = false;
            $data['error'] = $e->getMessage();
        }

        return response()->json([
            'message' => 'Service Layer with Transactions and Complex Queries',
            'data' => $data
        ]);
    }

    /**
     * Demonstrate custom collections and advanced filtering
     */
    public function customCollections()
    {
        $items = Item::all(); // Returns ItemCollection

        $data = [
            'collection_type' => get_class($items),
            'price_statistics' => $items->getPriceStatistics(),
            'price_ranges' => $items->groupByPriceRange(),
            'advanced_filtering' => $items->filterAdvanced([
                'price_min' => 1500,
                'price_max' => 3000,
                'search' => 'coffee',
                'is_premium' => true
            ]),
            'gift_recommendations' => $items->getGiftRecommendations(2500),
            'trending_items' => $items->getTrending(3),
            'personalized_recommendations' => $items->getRecommendations([
                'price_preference' => 'mid',
                'categories' => ['arabica', 'espresso']
            ]),
            'export_data' => $items->take(3)->export('array')
        ];

        return response()->json([
            'message' => 'Custom Collections and Advanced Data Manipulation',
            'data' => $data
        ]);
    }

    /**
     * Demonstrate complex database operations
     */
    public function complexQueries()
    {
        $data = [];

        // 1. Raw queries with parameter binding
        $data['monthly_sales'] = DB::select("
            SELECT 
                DATE_FORMAT(OrderDate, '%Y-%m') as month,
                COUNT(*) as total_orders,
                SUM(SubTotal) as total_revenue,
                AVG(SubTotal) as avg_order_value
            FROM orders 
            WHERE OrderDate >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
            GROUP BY DATE_FORMAT(OrderDate, '%Y-%m')
            ORDER BY month DESC
        ");

        // 2. Subquery demonstrations
        $data['customers_above_average'] = User::whereHas('orders', function ($query) {
            $avgOrderValue = Order::avg('SubTotal');
            $query->where('SubTotal', '>', $avgOrderValue);
        })->withCount('orders')->get();

        // 3. Union queries
        $highValueOrders = Order::where('SubTotal', '>', 5000);
        $recentOrders = Order::where('OrderDate', '>', now()->subDays(7));
        $data['combined_orders'] = $highValueOrders->union($recentOrders)->get();

        // 4. Window functions (if supported by your MySQL version)
        $data['items_with_ranking'] = DB::select("
            SELECT 
                ItemID,
                Name,
                Price,
                ROW_NUMBER() OVER (ORDER BY Price DESC) as price_rank
            FROM items 
            LIMIT 10
        ");

        return response()->json([
            'message' => 'Complex Database Operations and Raw Queries',
            'data' => $data
        ]);
    }

    /**
     * Performance optimization demonstrations
     */
    public function performanceOptimizations()
    {
        $data = [];

        // 1. N+1 Problem Solution
        $ordersWithItems = Order::with(['orderItems.item', 'user', 'payments'])
                               ->limit(10)
                               ->get();
        $data['optimized_orders'] = $ordersWithItems;

        // 2. Chunking for large datasets
        $itemCount = 0;
        Item::chunk(50, function ($items) use (&$itemCount) {
            $itemCount += $items->count();
        });
        $data['chunked_processing'] = "Processed {$itemCount} items in chunks";

        // 3. Lazy collections for memory efficiency
        $data['lazy_collection_demo'] = Item::cursor()->take(5)->map(function ($item) {
            return $item->only(['ItemID', 'Name', 'Price']);
        })->toArray();

        // 4. Select only needed columns
        $data['optimized_selection'] = Item::select('ItemID', 'Name', 'Price')
                                          ->with(['orderItems:OrderID,ItemID,Quantity'])
                                          ->limit(5)
                                          ->get();

        return response()->json([
            'message' => 'Performance Optimization Techniques',
            'data' => $data
        ]);
    }
}