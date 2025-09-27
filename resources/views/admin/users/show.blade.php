@extends('layouts.app')

@section('content')
<div class="min-h-screen bg-gray-50 py-6">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <!-- Header -->
        <div class="bg-white shadow rounded-lg mb-6 p-6">
            <div class="flex justify-between items-center">
                <h1 class="text-3xl font-bold text-gray-900">User Details: {{ $user->name }}</h1>
                <div class="flex space-x-3">
                    <a href="{{ route('admin.users.edit', $user->id) }}" class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg transition duration-200">
                        Edit User
                    </a>
                    <a href="{{ route('admin.users.index') }}" class="bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded-lg transition duration-200">
                        Back to Users
                    </a>
                </div>
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- User Information -->
            <div class="bg-white shadow rounded-lg p-6">
                <h2 class="text-xl font-semibold text-gray-900 mb-4">User Information</h2>
                <dl class="space-y-4">
                    <div>
                        <dt class="text-sm font-medium text-gray-500">Full Name</dt>
                        <dd class="text-sm text-gray-900">{{ $user->name }}</dd>
                    </div>
                    <div>
                        <dt class="text-sm font-medium text-gray-500">Email</dt>
                        <dd class="text-sm text-gray-900">{{ $user->email }}</dd>
                    </div>
                    <div>
                        <dt class="text-sm font-medium text-gray-500">Role</dt>
                        <dd class="text-sm">
                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full 
                                {{ ($user->Role ?? 'customer') === 'admin' ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800' }}">
                                {{ ucfirst($user->Role ?? 'customer') }}
                            </span>
                        </dd>
                    </div>
                    <div>
                        <dt class="text-sm font-medium text-gray-500">Phone</dt>
                        <dd class="text-sm text-gray-900">{{ $user->Phone ?? 'Not provided' }}</dd>
                    </div>
                    <div>
                        <dt class="text-sm font-medium text-gray-500">Delivery Address</dt>
                        <dd class="text-sm text-gray-900">{{ $user->DeliveryAddress ?? 'Not provided' }}</dd>
                    </div>
                    <div>
                        <dt class="text-sm font-medium text-gray-500">Member Since</dt>
                        <dd class="text-sm text-gray-900">{{ $user->created_at ? $user->created_at->format('F j, Y') : 'Unknown' }}</dd>
                    </div>
                    <div>
                        <dt class="text-sm font-medium text-gray-500">Last Updated</dt>
                        <dd class="text-sm text-gray-900">{{ $user->updated_at ? $user->updated_at->format('F j, Y g:i A') : 'Unknown' }}</dd>
                    </div>
                </dl>
            </div>

            <!-- User Statistics -->
            <div class="bg-white shadow rounded-lg p-6">
                <h2 class="text-xl font-semibold text-gray-900 mb-4">User Statistics</h2>
                <dl class="space-y-4">
                    <div>
                        <dt class="text-sm font-medium text-gray-500">Total Orders</dt>
                        <dd class="text-2xl font-bold text-indigo-600">{{ $user->orders->count() ?? 0 }}</dd>
                    </div>
                    <div>
                        <dt class="text-sm font-medium text-gray-500">Total Spent</dt>
                        <dd class="text-2xl font-bold text-green-600">${{ number_format($user->totalSpent(), 2) }}</dd>
                    </div>
                    <div>
                        <dt class="text-sm font-medium text-gray-500">Email Verified</dt>
                        <dd class="text-sm">
                            @if($user->email_verified_at)
                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                                    Verified
                                </span>
                            @else
                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">
                                    Not Verified
                                </span>
                            @endif
                        </dd>
                    </div>
                    <div>
                        <dt class="text-sm font-medium text-gray-500">Last Login</dt>
                        <dd class="text-sm text-gray-900">{{ $user->last_login_at ? $user->last_login_at->format('F j, Y g:i A') : 'Never' }}</dd>
                    </div>
                </dl>
            </div>
        </div>

        <!-- Recent Orders -->
        @if($user->orders && $user->orders->count() > 0)
        <div class="bg-white shadow rounded-lg mt-6 p-6">
            <h2 class="text-xl font-semibold text-gray-900 mb-4">Recent Orders</h2>
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Order ID</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Total</th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        @foreach($user->orders->take(5) as $order)
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                                    #{{ $order->OrderID }}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                    {{ $order->OrderDate ? \Carbon\Carbon::parse($order->OrderDate)->format('M d, Y') : 'N/A' }}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">
                                        {{ $order->Status ?? 'Pending' }}
                                    </span>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                    ${{ number_format($order->SubTotal ?? 0, 2) }}
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
        @endif

        <!-- Action Buttons -->
        <div class="bg-white shadow rounded-lg mt-6 p-6">
            <h2 class="text-xl font-semibold text-gray-900 mb-4">Actions</h2>
            <div class="flex flex-wrap gap-3">
                <a href="{{ route('admin.users.edit', $user->id) }}" 
                   class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg transition duration-200">
                    Edit User
                </a>
                <form action="{{ route('admin.users.destroy', $user->id) }}" method="POST" 
                      onsubmit="return confirm('Are you sure you want to delete this user?')" class="inline">
                    @csrf
                    @method('DELETE')
                    <button type="submit" 
                            class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg transition duration-200">
                        Delete User
                    </button>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection