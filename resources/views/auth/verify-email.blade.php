@extends('layouts.public')

@section('title', 'Verify Email - eBrew Café')

@section('content')
<div class="max-w-md mx-auto mt-20 mb-20 bg-white p-6 rounded shadow">
    <h2 class="text-2xl font-bold mb-4 text-center">Email Verification</h2>

    <div class="mb-4 text-sm text-gray-600">
        {{ __('Before continuing, please verify your email by clicking the link we just sent. If you did not receive the email, we can send another.') }}
    </div>

    @if (session('status') == 'verification-link-sent')
        <div class="mb-4 font-medium text-sm text-green-600 text-center">
            {{ __('A new verification link has been sent to your email address.') }}
        </div>
    @endif

    <div class="mt-4 flex flex-col sm:flex-row items-center justify-between gap-4">
        {{-- Resend Verification Form --}}
        <form method="POST" action="{{ route('verification.send') }}" class="flex-1">
            @csrf
            <x-button type="submit" class="w-full">
                {{ __('Resend Verification Email') }}
            </x-button>
        </form>

        {{-- Edit Profile & Logout --}}
        <div class="flex flex-1 items-center justify-end gap-2 flex-wrap">
            <a href="{{ route('profile.show') }}" 
               class="underline text-sm text-gray-600 hover:text-gray-900 rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
               {{ __('Edit Profile') }}
            </a>

            <form method="POST" action="{{ route('logout') }}">
                @csrf
                <button type="submit" 
                    class="underline text-sm text-gray-600 hover:text-gray-900 rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                    {{ __('Log Out') }}
                </button>
            </form>
        </div>
    </div>
</div>
@endsection
