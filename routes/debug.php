<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;

// Temporary debug routes - REMOVE IN PRODUCTION
Route::prefix('debug')->group(function () {
    
    Route::get('/logs', function () {
        $logPath = storage_path('logs/laravel.log');
        
        if (!File::exists($logPath)) {
            return response()->json(['error' => 'Log file not found at: ' . $logPath]);
        }
        
        // Get last 200 lines
        $content = File::get($logPath);
        $lines = explode("\n", $content);
        $lastLines = array_slice($lines, -200);
        
        return response("<pre>" . htmlspecialchars(implode("\n", $lastLines)) . "</pre>")
            ->header('Content-Type', 'text/html');
    });
    
    Route::get('/permissions', function () {
        $checks = [];
        
        // Check storage permissions
        $storagePath = storage_path();
        $checks['storage_path'] = $storagePath;
        $checks['storage_writable'] = is_writable($storagePath);
        $checks['storage_perms'] = substr(sprintf('%o', fileperms($storagePath)), -4);
        
        // Check sessions directory
        $sessionsPath = storage_path('framework/sessions');
        $checks['sessions_exists'] = File::exists($sessionsPath);
        $checks['sessions_writable'] = File::exists($sessionsPath) ? is_writable($sessionsPath) : false;
        if (File::exists($sessionsPath)) {
            $checks['sessions_files_count'] = count(File::files($sessionsPath));
        }
        
        // Check bootstrap/cache
        $cachePath = base_path('bootstrap/cache');
        $checks['cache_path'] = $cachePath;
        $checks['cache_writable'] = is_writable($cachePath);
        $checks['cache_perms'] = substr(sprintf('%o', fileperms($cachePath)), -4);
        
        // Check for config cache
        $configCachePath = base_path('bootstrap/cache/config.php');
        $checks['config_cached'] = File::exists($configCachePath);
        
        // Check environment
        $checks['app_env'] = config('app.env');
        $checks['app_debug'] = config('app.debug');
        $checks['app_url'] = config('app.url');
        $checks['session_driver'] = config('session.driver');
        $checks['session_secure'] = config('session.secure');
        
        return response()->json($checks, 200, [], JSON_PRETTY_PRINT);
    });
    
    Route::get('/clear-caches', function () {
        try {
            \Artisan::call('view:clear');
            \Artisan::call('cache:clear');
            \Artisan::call('config:clear');
            \Artisan::call('route:clear');
            \Artisan::call('optimize:clear');
            
            return response()->json([
                'success' => true,
                'message' => 'All caches cleared successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage()
            ]);
        }
    });
    
    Route::get('/test-faq', function () {
        try {
            // Test FAQ route manually
            $controller = new \App\Http\Controllers\FaqController();
            ob_start();
            $result = $controller->index();
            $output = ob_get_clean();
            
            return response()->json([
                'success' => true,
                'controller_result' => 'FAQ controller executed successfully',
                'view_type' => get_class($result)
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
        }
    });
    
    Route::get('/session-test', function () {
        try {
            // Test session functionality
            session()->put('test_key', 'test_value_' . time());
            $retrieved = session()->get('test_key');
            
            return response()->json([
                'session_works' => $retrieved !== null,
                'session_id' => session()->getId(),
                'session_driver' => config('session.driver'),
                'test_value' => $retrieved
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'session_works' => false,
                'error' => $e->getMessage()
            ]);
        }
    });
});