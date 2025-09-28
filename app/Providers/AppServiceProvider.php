<?php

namespace App\Providers;

use App\Models\Order;
use App\Observers\OrderObserver;
use Illuminate\Support\Facades\URL;
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
            $appUrl = config('app.url');

            // Force Laravel to generate HTTPS URLs
            URL::forceScheme('https');
            URL::forceRootUrl($appUrl);

            // Set asset URL so Vite uses HTTPS
            config(['app.asset_url' => $appUrl]);
        }
    }
}