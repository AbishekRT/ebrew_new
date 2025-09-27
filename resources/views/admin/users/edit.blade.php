@extends('layouts.app')

@section('content')
<div class="min-h-screen bg-gray-50 py-6">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <!-- Header -->
        <div class="bg-white shadow rounded-lg mb-6 p-6">
            <div class="flex justify-between items-center">
                <h1 class="text-3xl font-bold text-gray-900">Edit User: {{ $user->name }}</h1>
                <a href="{{ route('admin.users.index') }}" class="bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded-lg transition duration-200">
                    Back to Users
                </a>
            </div>
        </div>

        @if(session('success'))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
                {{ session('success') }}
            </div>
        @endif

        @if ($errors->any())
            <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
                <ul class="list-disc list-inside">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <!-- Edit User Form -->
        <div class="bg-white shadow rounded-lg p-6">
            <form action="{{ route('admin.users.update', $user->id) }}" method="POST" class="grid grid-cols-1 md:grid-cols-2 gap-6">
                @csrf
                @method('PUT')
                
                <div class="space-y-4">
                    <div>
                        <label for="name" class="block text-sm font-medium text-gray-700">Full Name</label>
                        <input type="text" id="name" name="name" value="{{ old('name', $user->name) }}" required
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                    </div>

                    <div>
                        <label for="email" class="block text-sm font-medium text-gray-700">Email</label>
                        <input type="email" id="email" name="email" value="{{ old('email', $user->email) }}" required
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                    </div>

                    <div>
                        <label for="phone" class="block text-sm font-medium text-gray-700">Phone</label>
                        <input type="text" id="phone" name="phone" value="{{ old('phone', $user->Phone) }}"
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                    </div>

                    <div>
                        <label for="role" class="block text-sm font-medium text-gray-700">Role</label>
                        <select id="role" name="Role" required
                                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                            <option value="customer" {{ (old('Role', $user->Role) === 'customer') ? 'selected' : '' }}>Customer</option>
                            <option value="admin" {{ (old('Role', $user->Role) === 'admin') ? 'selected' : '' }}>Admin</option>
                        </select>
                    </div>
                </div>

                <div class="space-y-4">
                    <div>
                        <label for="address" class="block text-sm font-medium text-gray-700">Delivery Address</label>
                        <textarea id="address" name="address" rows="4"
                                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">{{ old('address', $user->DeliveryAddress) }}</textarea>
                    </div>

                    <div>
                        <label for="password" class="block text-sm font-medium text-gray-700">New Password</label>
                        <input type="password" id="password" name="password"
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                        <p class="mt-2 text-sm text-gray-500">Leave blank to keep current password</p>
                    </div>

                    <div>
                        <label for="password_confirmation" class="block text-sm font-medium text-gray-700">Confirm New Password</label>
                        <input type="password" id="password_confirmation" name="password_confirmation"
                               class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                    </div>

                    <div class="flex justify-end space-x-3">
                        <a href="{{ route('admin.users.index') }}" 
                           class="bg-gray-600 hover:bg-gray-700 text-white px-6 py-2 rounded-lg transition duration-200">
                            Cancel
                        </a>
                        <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2 rounded-lg transition duration-200">
                            Update User
                        </button>
                    </div>
                </div>
            </form>

            <!-- Delete User Section -->
            <div class="border-t border-gray-200 mt-8 pt-8">
                <div class="bg-red-50 border border-red-200 rounded-lg p-4">
                    <div class="flex">
                        <div class="flex-shrink-0">
                            <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                            </svg>
                        </div>
                        <div class="ml-3">
                            <h3 class="text-sm font-medium text-red-800">Danger Zone</h3>
                            <div class="mt-2 text-sm text-red-700">
                                <p>Once you delete this user, there is no going back. Please be certain.</p>
                            </div>
                            <div class="mt-4">
                                <form action="{{ route('admin.users.destroy', $user->id) }}" method="POST" 
                                      onsubmit="return confirm('Are you absolutely sure you want to delete this user? This action cannot be undone.')" class="inline">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" 
                                            class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition duration-200">
                                        Delete User
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection