<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Auth\Access\Response;

class UserPolicy
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
    public function view(User $user, User $model): bool
    {
        // Admin can view any user, users can view their own profile
        return $user->Role === 'admin' || $user->id === $model->id;
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return $user->Role === 'admin';
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, User $model): bool
    {
        // Admin can update any user, users can update their own profile
        return $user->Role === 'admin' || $user->id === $model->id;
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, User $model): bool
    {
        // Admin can delete users, but not themselves
        return $user->Role === 'admin' && $user->id !== $model->id;
    }

    /**
     * Determine whether the user can restore the model.
     */
    public function restore(User $user, User $model): bool
    {
        return $user->Role === 'admin';
    }

    /**
     * Determine whether the user can permanently delete the model.
     */
    public function forceDelete(User $user, User $model): bool
    {
        return $user->Role === 'admin' && $user->id !== $model->id;
    }

    /**
     * Determine if user can manage roles
     */
    public function manageRoles(User $user): bool
    {
        return $user->Role === 'admin';
    }

    /**
     * Determine if user can change another user's role
     */
    public function changeRole(User $user, User $model): bool
    {
        // Admin can change roles, but not their own
        return $user->Role === 'admin' && $user->id !== $model->id;
    }

    /**
     * Determine if user can view admin dashboard
     */
    public function viewAdminDashboard(User $user): bool
    {
        return $user->Role === 'admin';
    }

    /**
     * Determine if user can impersonate other users
     */
    public function impersonate(User $user, User $model): bool
    {
        return $user->Role === 'admin' && $user->id !== $model->id;
    }
}
