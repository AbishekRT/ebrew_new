<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>@yield('title', config('app.name', 'eBrew Café')) - Asset Debug</title>

    <!-- Debug Info -->
    <style>
        .debug-info {
            background: #f0f0f0;
            padding: 15px;
            margin: 10px 0;
            border: 1px solid #ddd;
            font-family: monospace;
            white-space: pre-wrap;
        }
    </style>
</head>
<body style="font-family: Arial, sans-serif; margin: 20px;">
    <h1>Asset Loading Debug Information</h1>
    
    <div class="debug-info">
APP_ENV: {{ config('app.env') }}
APP_URL: {{ config('app.url') }}
APP_DEBUG: {{ config('app.debug') ? 'true' : 'false' }}

Asset Manifest Path: {{ public_path('build/manifest.json') }}
Manifest Exists: {{ file_exists(public_path('build/manifest.json')) ? 'YES' : 'NO' }}

@if(file_exists(public_path('build/manifest.json')))
Manifest Content:
{{ file_get_contents(public_path('build/manifest.json')) }}
@endif

Vite Assets:
@php
    try {
        echo "CSS URL: " . Vite::asset('resources/css/app.css') . "\n";
        echo "JS URL: " . Vite::asset('resources/js/app.js') . "\n";
    } catch (Exception $e) {
        echo "Vite Error: " . $e->getMessage() . "\n";
    }
@endphp

Current URL: {{ url()->current() }}
Base URL: {{ url('/') }}
    </div>

    <h2>Expected vs Actual Styles</h2>
    <div style="padding: 20px;">
        <!-- Test if Tailwind classes work -->
        <div class="bg-blue-500 text-white p-4 rounded shadow-lg mb-4">
            <h3 class="text-xl font-bold">This should be blue with white text</h3>
            <p>If this appears unstyled, Tailwind CSS isn't loading</p>
        </div>
        
        <div style="background: blue; color: white; padding: 16px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); margin-bottom: 16px;">
            <h3 style="font-size: 1.25rem; font-weight: bold; margin: 0 0 8px 0;">This should look identical (inline styles)</h3>
            <p style="margin: 0;">Comparison reference</p>
        </div>
    </div>

    <!-- Load Vite assets -->
    @vite(['resources/css/app.css', 'resources/js/app.js'])

    <script>
        console.log('JavaScript loaded successfully');
        console.log('Current URL:', window.location.href);
        console.log('Base URL:', document.querySelector('base')?.href || 'No base tag');
        
        // Check if CSS loaded
        const testEl = document.createElement('div');
        testEl.className = 'bg-red-500';
        document.body.appendChild(testEl);
        const styles = window.getComputedStyle(testEl);
        console.log('Tailwind test - background color:', styles.backgroundColor);
        document.body.removeChild(testEl);
    </script>
</body>
</html>