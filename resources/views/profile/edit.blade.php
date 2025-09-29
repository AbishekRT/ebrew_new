@extends('layouts.app')

@section('content')
<div class="max-w-4xl mx-auto px-6 py-8 space-y-8 mt-5 mb-10">
    <!-- Page Header -->
    <div class="text-center">
        <h1 class="text-3xl font-bold text-yellow-900">Profile Settings</h1>
        <p class="text-gray-600 mt-2">Update your account information and password</p>
    </div>

    <!-- Success Messages -->
    @if (session('status') === 'profile-updated')
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
            Profile updated successfully!
        </div>
    @endif

    @if (session('status') === 'password-updated')
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
            Password updated successfully!
        </div>
    @endif

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Profile Information -->
        <div class="bg-white rounded-2xl shadow-lg p-6">
            <h2 class="text-xl font-bold text-gray-800 mb-6">Profile Information</h2>
            
            <form method="POST" action="{{ route('profile.update') }}">
                @csrf
                @method('patch')

                <div class="space-y-4">
                    <!-- Name -->
                    <div>
                        <label for="name" class="block text-sm font-medium text-gray-700 mb-2">Name</label>
                        <input type="text" name="name" id="name" 
                               value="{{ old('name', $user->name) }}" 
                               class="w-full px-3 py-2 border rounded-md focus:ring-yellow-500 focus:border-yellow-500 @if($errors->has('name')) border-red-500 @else border-gray-300 @endif" 
                               required>
                        @error('name')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>

                    <!-- Email -->
                    <div>
                        <label for="email" class="block text-sm font-medium text-gray-700 mb-2">Email</label>
                        <input type="email" name="email" id="email" 
                               value="{{ old('email', $user->email) }}" 
                               class="w-full px-3 py-2 border rounded-md focus:ring-yellow-500 focus:border-yellow-500 @if($errors->has('email')) border-red-500 @else border-gray-300 @endif" 
                               required>
                        @error('email')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                        
                        @if ($user instanceof \Illuminate\Contracts\Auth\MustVerifyEmail && ! $user->hasVerifiedEmail())
                            <p class="text-sm text-yellow-600 mt-2">
                                Your email address is unverified.
                                <button form="send-verification" class="underline text-sm text-yellow-600 hover:text-yellow-900">
                                    Click here to re-send the verification email.
                                </button>
                            </p>
                        @endif
                    </div>

                    <!-- Submit Button -->
                    <div class="flex justify-end">
                        <button type="submit" 
                                class="bg-yellow-600 hover:bg-yellow-700 text-white px-6 py-2 rounded-md text-sm font-medium">
                            Save Changes
                        </button>
                    </div>
                </div>
            </form>
        </div>

        <!-- Update Password -->
        <div class="bg-white rounded-2xl shadow-lg p-6">
            <h2 class="text-xl font-bold text-gray-800 mb-6">Update Password</h2>
            
            <form method="POST" action="{{ route('profile.password.update') }}">
                @csrf
                @method('patch')

                <div class="space-y-4">
                    <!-- Current Password -->
                    <div>
                        <label for="current_password" class="block text-sm font-medium text-gray-700 mb-2">Current Password</label>
                        <input type="password" name="current_password" id="current_password" 
                               class="w-full px-3 py-2 border rounded-md focus:ring-yellow-500 focus:border-yellow-500 @if($errors->has('current_password')) border-red-500 @else border-gray-300 @endif" 
                               required>
                        @error('current_password')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>

                    <!-- New Password -->
                    <div>
                        <label for="password" class="block text-sm font-medium text-gray-700 mb-2">New Password</label>
                        <input type="password" name="password" id="password" 
                               class="w-full px-3 py-2 border rounded-md focus:ring-yellow-500 focus:border-yellow-500 @if($errors->has('password')) border-red-500 @else border-gray-300 @endif" 
                               required>
                        @error('password')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>

                    <!-- Confirm Password -->
                    <div>
                        <label for="password_confirmation" class="block text-sm font-medium text-gray-700 mb-2">Confirm Password</label>
                        <input type="password" name="password_confirmation" id="password_confirmation" 
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-yellow-500 focus:border-yellow-500" 
                               required>
                    </div>

                    <!-- Submit Button -->
                    <div class="flex justify-end">
                        <button type="submit" 
                                class="bg-yellow-600 hover:bg-yellow-700 text-white px-6 py-2 rounded-md text-sm font-medium">
                            Update Password
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- Back to Dashboard -->
    <div class="text-center">
        <a href="{{ route('dashboard') }}" 
           class="inline-flex items-center px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white text-sm font-medium rounded-md">
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
            </svg>
            Back to Dashboard
        </a>
    </div>
</div>

@if ($user instanceof \Illuminate\Contracts\Auth\MustVerifyEmail && ! $user->hasVerifiedEmail())
    <form id="send-verification" method="post" action="{{ route('verification.send') }}">
        @csrf
    </form>
@endif
@endsection