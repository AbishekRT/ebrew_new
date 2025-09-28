<?php

namespace App\Providers;

use App\Models\Order;
use App\Observers\OrderObserver;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\Vite;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Register model observers
        Order::observe(OrderObserver::class);
        
        // Force HTTPS in production (Railway uses HTTPS)
        if (app()->environment('production')) {
            URL::forceScheme('https');
            
            // Ensure Vite uses correct URLs in production
            if (config('app.url')) {
                $appUrl = config('app.url');
                // Make sure asset URLs use the correct domain
                config(['app.asset_url' => $appUrl]);
            }
        }
    }
}