<?php

namespace App\Policies;

use App\Models\Order;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class OrderPolicy
{
    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return $user->Role === 'admin';
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, Order $order): bool
    {
        // Admin can view any order, users can only view their own orders
        return $user->Role === 'admin' || $user->id === $order->UserID;
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        // Any authenticated user can create orders
        return true;
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Order $order): bool
    {
        // Only admins can update orders
        return $user->Role === 'admin';
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Order $order): bool
    {
        // Only admins can delete orders
        return $user->Role === 'admin';
    }

    /**
     * Determine whether the user can restore the model.
     */
    public function restore(User $user, Order $order): bool
    {
        return $user->Role === 'admin';
    }

    /**
     * Determine whether the user can permanently delete the model.
     */
    public function forceDelete(User $user, Order $order): bool
    {
        return $user->Role === 'admin';
    }

    /**
     * Determine if user can cancel an order
     */
    public function cancel(User $user, Order $order): bool
    {
        // Users can cancel their own pending orders, admins can cancel any order
        if ($user->Role === 'admin') {
            return true;
        }

        // Users can only cancel their own orders that are still pending
        return $user->id === $order->UserID && $order->status !== 'completed';
    }

    /**
     * Determine if user can view order payments
     */
    public function viewPayments(User $user, Order $order): bool
    {
        return $user->Role === 'admin' || $user->id === $order->UserID;
    }

    /**
     * Determine if user can process payments for an order
     */
    public function processPayment(User $user, Order $order): bool
    {
        // Users can pay for their own orders, admins can process any payment
        return $user->Role === 'admin' || $user->id === $order->UserID;
    }
}
