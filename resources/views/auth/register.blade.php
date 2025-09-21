<x-guest-layout>
    <main class="max-w-md mx-auto mt-10 mb-10 bg-white p-6 rounded shadow">
        <h2 class="text-2xl font-bold mb-4 text-center">Create an Account</h2>

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

        {{-- Display success messages --}}
        @if (session('success'))
            <p class="bg-green-100 text-green-700 p-2 rounded text-sm text-center mb-4">
                {{ session('success') }}
            </p>
        @endif

        <form action="{{ route('register') }}" method="POST" class="space-y-4">
            @csrf

            <!-- Full Name -->
            <input type="text" name="full_name" placeholder="Full Name" value="{{ old('full_name') }}" required
                class="w-full p-2 border border-gray-300 rounded" />

            <!-- Email -->
            <input type="email" name="email" placeholder="Email" value="{{ old('email') }}" required
                class="w-full p-2 border border-gray-300 rounded" />

            <!-- Password -->
            <input type="password" name="password" placeholder="Password" required
                class="w-full p-2 border border-gray-300 rounded" />

            <!-- Confirm Password -->
            <input type="password" name="password_confirmation" placeholder="Confirm Password" required
                class="w-full p-2 border border-gray-300 rounded" />

            <!-- Phone Number (optional) -->
            <input type="text" name="phone" placeholder="Phone Number" value="{{ old('phone') }}"
                class="w-full p-2 border border-gray-300 rounded" />

            <!-- Delivery Address (optional) -->
            <textarea name="address" placeholder="Delivery Address"
                class="w-full p-2 border border-gray-300 rounded">{{ old('address') }}</textarea>

            <!-- Submit Button -->
            <button type="submit" class="bg-[#2d0d1c] hover:bg-[#4a1a33] text-white px-4 py-2 rounded w-full">
                Create Account
            </button>
        </form>

        <p class="mt-4 text-center">Already have an account?
            <a href="{{ route('login') }}" class="text-blue-600 hover:underline">Login here</a>
        </p>
    </main>
</x-guest-layout>
