<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Configure auth middleware to redirect to custom login route
        $middleware->redirectUsersTo(fn () => route('login'));
        
        // Register custom middleware
        $middleware->alias([
            'isAdmin' => \App\Http\Middleware\IsAdminMiddleware::class,
            'api.analytics' => \App\Http\Middleware\ApiAnalyticsMiddleware::class,
        ]);

        // Apply API analytics middleware to API routes
        $middleware->group('api', [
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
            \App\Http\Middleware\ApiAnalyticsMiddleware::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();
