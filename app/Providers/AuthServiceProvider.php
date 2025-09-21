<?php

namespace App\Providers;

use App\Models\Order;
use App\Models\User;
use App\Policies\OrderPolicy;
use App\Policies\UserPolicy;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Gate;

class AuthServiceProvider extends ServiceProvider
{
    /**
     * The model to policy mappings for the application.
     *
     * @var array<class-string, class-string>
     */
    protected $policies = [
        Order::class => OrderPolicy::class,
        User::class => UserPolicy::class,
    ];

    /**
     * Register any authentication / authorization services.
     */
    public function boot(): void
    {
        $this->registerPolicies();

        // Define additional gates
        Gate::define('access-admin-panel', function (User $user) {
            return $user->isAdmin();
        });

        Gate::define('view-login-history', function (User $user, ?User $targetUser = null) {
            // Admins can view any user's login history
            if ($user->isAdmin()) {
                return true;
            }
            
            // Users can only view their own login history
            return $targetUser && $user->id === $targetUser->id;
        });

        Gate::define('manage-users', function (User $user) {
            return $user->isAdmin();
        });

        Gate::define('view-security-dashboard', function (User $user) {
            return $user->isAdmin();
        });

        Gate::define('force-logout', function (User $user, User $targetUser) {
            return $user->isAdmin() && $user->id !== $targetUser->id;
        });
    }
}