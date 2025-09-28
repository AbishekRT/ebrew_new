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
            
            // Force all asset URLs to use HTTPS
            if (config('app.url')) {
                $appUrl = config('app.url');
                // Ensure asset URLs use HTTPS
                config(['app.asset_url' => $appUrl]);
                
                // Force root URL to use HTTPS
                URL::forceRootUrl($appUrl);
            }
            
            // Additional security headers
            if (request()->isSecure()) {
                URL::forceScheme('https');
            }
        }
    }
}