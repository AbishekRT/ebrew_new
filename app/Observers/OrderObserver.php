<?php

namespace App\Observers;

use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class OrderObserver
{
    /**
     * Handle the Order "creating" event.
     */
    public function creating(Order $order)
    {
        // Auto-set order date if not provided
        if (!$order->OrderDate) {
            $order->OrderDate = now();
        }
        
        // Generate order number or reference
        $order->OrderReference = 'ORD-' . now()->format('Ymd') . '-' . str_pad(Order::count() + 1, 4, '0', STR_PAD_LEFT);
        
        Log::info('Order being created', ['order_data' => $order->toArray()]);
    }

    /**
     * Handle the Order "created" event.
     */
    public function created(Order $order)
    {
        // Clear relevant caches
        Cache::forget('recent_orders');
        Cache::forget("user_orders_{$order->UserID}");
        Cache::forget('orders_statistics');
        
        // Send notification (example)
        $this->sendOrderConfirmation($order);
        
        Log::info('Order created successfully', ['order_id' => $order->OrderID]);
    }

    /**
     * Handle the Order "updating" event.
     */
    public function updating(Order $order)
    {
        // Log changes for audit trail
        $changes = $order->getDirty();
        if (!empty($changes)) {
            Log::info('Order being updated', [
                'order_id' => $order->OrderID,
                'changes' => $changes
            ]);
        }
    }

    /**
     * Handle the Order "updated" event.
     */
    public function updated(Order $order)
    {
        // Clear caches when order is updated
        Cache::forget("order_{$order->OrderID}");
        Cache::forget("user_orders_{$order->UserID}");
        Cache::forget('orders_statistics');
        
        Log::info('Order updated successfully', ['order_id' => $order->OrderID]);
    }

    /**
     * Handle the Order "deleted" event.
     */
    public function deleted(Order $order)
    {
        // Clean up related data and caches
        Cache::forget("order_{$order->OrderID}");
        Cache::forget("user_orders_{$order->UserID}");
        Cache::forget('recent_orders');
        Cache::forget('orders_statistics');
        
        Log::warning('Order deleted', ['order_id' => $order->OrderID]);
    }

    /**
     * Send order confirmation notification
     */
    private function sendOrderConfirmation(Order $order)
    {
        // This would typically send an email or notification
        // For now, just log it
        Log::info('Order confirmation sent', [
            'order_id' => $order->OrderID,
            'user_id' => $order->UserID
        ]);
    }
}