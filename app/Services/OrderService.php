<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\User;
use App\Models\Item;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Exception;

class OrderService
{
    /**
     * Create order from cart with database transaction
     */
    public function createOrderFromCart(User $user): Order
    {
        return DB::transaction(function () use ($user) {
            // Get user's cart with optimized eager loading
            $cart = Cart::withItems()
                       ->where('UserID', $user->id)
                       ->firstOrFail();

            // Calculate total with single query
            $subTotal = $cart->items->sum(function ($cartItem) {
                return $cartItem->Quantity * $cartItem->item->Price;
            });

            // Create order
            $order = Order::create([
                'UserID' => $user->id,
                'OrderDate' => now(),
                'SubTotal' => $subTotal
            ]);

            // Bulk create order items
            $orderItemsData = $cart->items->map(function ($cartItem) use ($order) {
                return [
                    'OrderID' => $order->OrderID,
                    'ItemID' => $cartItem->ItemID,
                    'Quantity' => $cartItem->Quantity
                ];
            })->toArray();

            OrderItem::insert($orderItemsData);

            // Clear cart
            CartItem::where('CartID', $cart->CartID)->delete();

            // Cache invalidation
            Cache::forget("user_orders_{$user->id}");
            Cache::forget("recent_orders");

            return $order->load(['orderItems.item', 'user']);
        });
    }

    /**
     * Get advanced order statistics with complex aggregations
     */
    public function getOrderStatistics(array $filters = [])
    {
        $query = Order::query();

        // Apply filters using scopes
        if (isset($filters['date_from']) && isset($filters['date_to'])) {
            $query->dateRange($filters['date_from'], $filters['date_to']);
        }

        if (isset($filters['min_amount'])) {
            $query->highValue($filters['min_amount']);
        }

        // Complex aggregation with subqueries
        return $query->selectRaw('
                COUNT(*) as total_orders,
                SUM(SubTotal) as total_revenue,
                AVG(SubTotal) as average_order_value,
                MIN(SubTotal) as min_order_value,
                MAX(SubTotal) as max_order_value,
                COUNT(DISTINCT UserID) as unique_customers
            ')
            ->with(['orderItems' => function ($q) {
                $q->selectRaw('OrderID, COUNT(*) as item_count, SUM(Quantity) as total_quantity')
                  ->groupBy('OrderID');
            }])
            ->first();
    }

    /**
     * Get top customers with advanced querying
     */
    public function getTopCustomers($limit = 10)
    {
        return User::withCount(['orders'])
                   ->withSum('orders', 'SubTotal')
                   ->having('orders_count', '>', 0)
                   ->orderBy('orders_sum_sub_total', 'desc')
                   ->limit($limit)
                   ->get()
                   ->map(function ($user) {
                       return [
                           'user' => $user,
                           'total_spent' => $user->orders_sum_sub_total,
                           'total_orders' => $user->orders_count,
                           'average_order' => $user->orders_count > 0 
                               ? round($user->orders_sum_sub_total / $user->orders_count, 2) 
                               : 0
                       ];
                   });
    }

    /**
     * Get popular items with complex aggregations
     */
    public function getPopularItems($limit = 10, $days = 30)
    {
        return Item::select('items.*')
                   ->selectRaw('
                       COUNT(order_items.ItemID) as order_count,
                       SUM(order_items.Quantity) as total_quantity_sold,
                       SUM(order_items.Quantity * items.Price) as total_revenue
                   ')
                   ->join('order_items', 'items.ItemID', '=', 'order_items.ItemID')
                   ->join('orders', 'order_items.OrderID', '=', 'orders.OrderID')
                   ->where('orders.OrderDate', '>=', now()->subDays($days))
                   ->groupBy('items.ItemID', 'items.Name', 'items.Description', 'items.Price', 'items.TastingNotes', 'items.ShippingAndReturns', 'items.RoastDates', 'items.Image')
                   ->orderBy('total_quantity_sold', 'desc')
                   ->limit($limit)
                   ->get();
    }

    /**
     * Generate sales report with advanced analytics
     */
    public function generateSalesReport($startDate, $endDate)
    {
        return Cache::remember("sales_report_{$startDate}_{$endDate}", 3600, function () use ($startDate, $endDate) {
            $baseQuery = Order::dateRange($startDate, $endDate);

            $dailySales = $baseQuery->clone()
                ->selectRaw('DATE(OrderDate) as date, COUNT(*) as orders, SUM(SubTotal) as revenue')
                ->groupBy('date')
                ->orderBy('date')
                ->get();

            $topItems = $this->getPopularItems(5, now()->diffInDays($startDate));

            $customerAnalytics = User::whereHas('orders', function ($q) use ($startDate, $endDate) {
                    $q->dateRange($startDate, $endDate);
                })
                ->withCount(['orders' => function ($q) use ($startDate, $endDate) {
                    $q->dateRange($startDate, $endDate);
                }])
                ->withSum(['orders' => function ($q) use ($startDate, $endDate) {
                    $q->dateRange($startDate, $endDate);
                }], 'SubTotal')
                ->get();

            return [
                'period' => ['start' => $startDate, 'end' => $endDate],
                'summary' => $baseQuery->clone()->selectRaw('
                    COUNT(*) as total_orders,
                    SUM(SubTotal) as total_revenue,
                    AVG(SubTotal) as avg_order_value,
                    COUNT(DISTINCT UserID) as unique_customers
                ')->first(),
                'daily_sales' => $dailySales,
                'top_items' => $topItems,
                'customer_analytics' => $customerAnalytics
            ];
        });
    }

    /**
     * Process payment with transaction safety
     */
    public function processPayment(Order $order, array $paymentData): Payment
    {
        return DB::transaction(function () use ($order, $paymentData) {
            // Validate order exists and is unpaid
            $existingPayment = Payment::where('OrderID', $order->OrderID)
                                    ->where('PaymentStatus', 'paid')
                                    ->first();

            if ($existingPayment) {
                throw new Exception('Order is already paid');
            }

            // Create payment record
            $payment = Payment::create([
                'OrderID' => $order->OrderID,
                'PaymentDate' => now(),
                'PaymentAmount' => $paymentData['amount'],
                'PaymentStatus' => $paymentData['status'] ?? 'pending'
            ]);

            // If payment is successful, update inventory or perform other business logic
            if ($payment->PaymentStatus === 'paid') {
                $this->updateInventoryAfterPayment($order);
            }

            // Clear relevant caches
            Cache::forget("order_{$order->OrderID}");
            Cache::forget("user_orders_{$order->UserID}");

            return $payment;
        });
    }

    /**
     * Private method to handle inventory updates
     */
    private function updateInventoryAfterPayment(Order $order)
    {
        // This would typically update inventory levels
        // For now, just log the successful payment processing
        \Log::info("Payment processed for order {$order->OrderID}");
    }
}