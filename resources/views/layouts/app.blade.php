<x-guest-layout>
    <main class="max-w-md mx-auto mt-20 mb-20 bg-white p-6 rounded shadow">
        <h2 class="text-2xl font-bold mb-4 text-center">Login</h2>

        {{-- Display session feedback messages --}}
        @if (session('success'))
            <p class="bg-green-100 text-green-700 p-2 rounded text-sm text-center mb-4">
                {{ session('success') }}
            </p>
        @endif

        {{-- Display validation errors --}}
        @if ($errors->any())
            <div class="bg-red-100 text-red-700 p-2 rounded text-sm text-center mb-4">
                <ul class="list-disc list-inside">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('login') }}" method="POST" class="space-y-4">
            @csrf
            <input type="email" name="email" placeholder="Email" required
                class="w-full p-2 border border-gray-300 rounded" />
            <input type="password" name="password" placeholder="Password" required
                class="w-full p-2 border border-gray-300 rounded" />
            
            <div class="flex items-center justify-between mt-2">
                <label class="flex items-center">
                    <input type="checkbox" name="remember" class="mr-2">
                    Remember me
                </label>
                @if (Route::has('password.request'))
                    <a class="text-sm text-blue-600 hover:underline" href="{{ route('password.request') }}">
                        Forgot your password?
                    </a>
                @endif
            </div>

            <button type="submit" class="bg-[#2d0d1c] hover:bg-[#4a1a33] text-white px-4 py-2 rounded w-full">
                Login
            </button>
        </form>

        <p class="mt-4 text-center">Don't have an account?
            <a href="{{ route('register') }}" class="text-blue-600 hover:underline">Register here</a>
        </p>
    </main>
</x-guest-layout>
