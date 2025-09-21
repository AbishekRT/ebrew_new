<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>{{ config('app.name', 'Laravel') }}</title>

    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.bunny.net">
    <link href="https://fonts.bunny.net/css?family=figtree:400,500,600&display=swap" rel="stylesheet" />

    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" integrity="sha512-pbVd4V1sNn6gQG1YfV9F3U8Cn5C9I6y5n2/mcVnOqXPEyYo8rkQ1dIQp+hGhRYGq2C+Uo5c6Yq6Bz3T2Xoxq8w==" crossorigin="anonymous" referrerpolicy="no-referrer" />

    <!-- Scripts -->
    @vite(['resources/css/app.css', 'resources/js/app.js'])

    <!-- Styles -->
    @livewireStyles
</head>
<body class="font-sans text-gray-900 antialiased bg-gray-100">

    {{-- ✅ Add Header --}}
    @include('partials.header')

    <main class="min-h-screen flex flex-col justify-center items-center py-8">
        {{ $slot }}
    </main>

    {{-- ✅ Add Footer --}}
    @include('partials.footer')

    @livewireScripts
    
    <script>
        // Handle cart link clicks to prevent unnecessary page reload when already on cart page
        function handleCartClick(event) {
            // Check if we're already on the cart page
            if (window.location.pathname === '/cart') {
                event.preventDefault();
                // Optional: Show a message or simply do nothing
                console.log('Already on cart page');
                return false;
            }
            return true; // Allow normal navigation
        }
    </script>
</body>
</html>
