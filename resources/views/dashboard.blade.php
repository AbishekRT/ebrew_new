@extends('layouts.app')

@section('content')
<div class="max-w-6xl mx-auto px-6 py-8 space-y-10 mt-5 mb-10">
    
    <!-- Welcome Section -->
    <div class="text-center bg-white rounded-2xl shadow-lg p-8">
        <h1 class="text-4xl font-bold text-gray-800">
            Welcome, {{ $user->name }}!
        </h1>
        <p class="mt-2 text-lg text-gray-600">Your Personal Dashboard</p>
        <div class="mt-6 grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
            <div class="bg-blue-50 border border-blue-200 p-3 rounded-lg">
                <div class="font-semibold text-blue-700">Security Score</div>
                <div class="text-2xl font-bold text-blue-800">{{ $userStats['security_score'] }}/100</div>
            </div>
            <div class="bg-green-50 border border-green-200 p-3 rounded-lg">
                <div class="font-semibold text-green-700">Total Orders</div>
                <div class="text-2xl font-bold text-green-800">{{ $userStats['total_orders'] }}</div>
            </div>
            <div class="bg-purple-50 border border-purple-200 p-3 rounded-lg">
                <div class="font-semibold text-purple-700">Account Age</div>
                <div class="text-2xl font-bold text-purple-800">{{ $userStats['account_age_hours'] }} hours</div>
            </div>
            <div class="bg-orange-50 border border-orange-200 p-3 rounded-lg">
                <div class="font-semibold text-orange-700">Active Sessions</div>
                <div class="text-2xl font-bold text-orange-800">{{ $userStats['active_sessions'] }}</div>
            </div>
        </div>
    </div>

    <!-- MongoDB UserAnalytics Advanced Showcase -->
    <div class="bg-white rounded-2xl shadow-lg p-6">
        <h2 class="text-2xl font-bold text-gray-800 mb-6">
            Security Analytics & User Insights
        </h2>
        
        <!-- Security Overview -->
        <div class="mb-8">
            <h3 class="text-lg font-semibold text-gray-700 mb-4">Security Overview</h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
                    <div class="flex items-center justify-between">
                        <div>
                            <div class="text-sm font-medium text-blue-600">Total Sessions</div>
                            <div class="text-3xl font-bold text-blue-800">{{ $userAnalytics['total_sessions'] ?? 0 }}</div>
                            <div class="text-xs text-blue-500 mt-1">Active: {{ $userStats['active_sessions'] }}</div>
                        </div>
                        <div class="text-blue-400 text-3xl">
                            <i class="fas fa-shield-alt"></i>
                        </div>
                    </div>
                </div>
                <div class="bg-yellow-50 border border-yellow-200 rounded-xl p-4">
                    <div class="flex items-center justify-between">
                        <div>
                            <div class="text-sm font-medium text-yellow-600">Security Incidents</div>
                            <div class="text-3xl font-bold text-yellow-800">{{ $userAnalytics['security_incidents'] ?? 0 }}</div>
                            <div class="text-xs text-yellow-500 mt-1">{{ ucwords($userAnalytics['security_status'] ?? 'Low Risk') }}</div>
                        </div>
                        <div class="text-yellow-400 text-3xl">
                            <i class="fas fa-exclamation-triangle"></i>
                        </div>
                    </div>
                </div>
                <div class="bg-green-50 border border-green-200 rounded-xl p-4">
                    <div class="flex items-center justify-between">
                        <div>
                            <div class="text-sm font-medium text-green-600">Unique Devices</div>
                            <div class="text-3xl font-bold text-green-800">{{ count($userAnalytics['unique_devices'] ?? []) }}</div>
                            <div class="text-xs text-green-500 mt-1">Anomaly: {{ $anomalyData['anomaly_score'] ?? 0 }}%</div>
                        </div>
                        <div class="text-green-400 text-3xl">
                            <i class="fas fa-mobile-alt"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Behavior Patterns Showcase -->
        @if(!empty($behaviorPatterns))
        <div class="mb-6">
            <h3 class="text-lg font-semibold text-gray-700 mb-4">Advanced Behavior Analytics (Last 30 Days)</h3>
            <div class="bg-gradient-to-r from-purple-50 to-pink-50 border border-purple-200 rounded-xl p-6">
                <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                    @foreach($behaviorPatterns as $pattern => $data)
                    <div class="bg-white rounded-lg p-4 shadow-sm border">
                        <div class="text-sm font-medium text-gray-600 mb-1">{{ ucwords(str_replace('_', ' ', $pattern)) }}</div>
                        <div class="text-2xl font-bold text-purple-600">{{ is_array($data) ? count($data) : $data }}</div>
                        <div class="text-xs text-gray-500 mt-1">MongoDB Analytics</div>
                    </div>
                    @endforeach
                </div>
            </div>
        </div>
        @endif
    </div>

    <!-- MongoDB Cart Analytics & Shopping Insights -->
    <div class="bg-white rounded-2xl shadow-lg p-6">
        <div class="flex justify-between items-center mb-6">
            <h2 class="text-2xl font-bold text-gray-800 flex items-center">
                <i class="fas fa-shopping-bag text-indigo-600 mr-3"></i>
                My Shopping Insights
            </h2>
            @if(empty($cartInsights['month']['total_sessions']) || $cartInsights['month']['total_sessions'] == 0)
            <form action="{{ route('dashboard.generate-test-data') }}" method="POST" class="inline">
                @csrf
                <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg text-sm transition-colors shadow-md">
                    <i class="fas fa-magic mr-1"></i>Generate Test Data
                </button>
            </form>
            @endif
        </div>
        
        @if($cartInsights['month']['total_sessions'] > 0)
        <!-- Shopping Overview Cards -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            <!-- Today's Activity -->
            <div class="bg-gradient-to-br from-blue-50 to-blue-100 border border-blue-200 rounded-xl p-4">
                <div class="flex items-center justify-between mb-2">
                    <h3 class="text-sm font-semibold text-blue-700">Today's Activity</h3>
                    <i class="fas fa-calendar-day text-blue-500"></i>
                </div>
                <div class="space-y-1">
                    <div class="text-2xl font-bold text-blue-800">{{ $cartInsights['today']['sessions'] }}</div>
                    <div class="text-xs text-blue-600">
                        {{ $cartInsights['today']['products_viewed'] }} products viewed
                    </div>
                    <div class="text-xs text-blue-600">
                        ${{ number_format($cartInsights['today']['cart_value'], 2) }} cart value
                    </div>
                </div>
            </div>

            <!-- Weekly Performance -->
            <div class="bg-gradient-to-br from-green-50 to-green-100 border border-green-200 rounded-xl p-4">
                <div class="flex items-center justify-between mb-2">
                    <h3 class="text-sm font-semibold text-green-700">This Week</h3>
                    <i class="fas fa-chart-line text-green-500"></i>
                </div>
                <div class="space-y-1">
                    <div class="text-2xl font-bold text-green-800">{{ $cartInsights['week']['conversion_rate'] }}%</div>
                    <div class="text-xs text-green-600">Conversion Rate</div>
                    <div class="text-xs text-green-600">
                        {{ $cartInsights['week']['avg_session_duration'] }} min avg session
                    </div>
                </div>
            </div>

            <!-- Monthly Stats -->
            <div class="bg-gradient-to-br from-purple-50 to-purple-100 border border-purple-200 rounded-xl p-4">
                <div class="flex items-center justify-between mb-2">
                    <h3 class="text-sm font-semibold text-purple-700">This Month</h3>
                    <i class="fas fa-calendar-alt text-purple-500"></i>
                </div>
                <div class="space-y-1">
                    <div class="text-2xl font-bold text-purple-800">{{ $cartInsights['month']['total_sessions'] }}</div>
                    <div class="text-xs text-purple-600">Total Sessions</div>
                    <div class="text-xs text-purple-600">
                        ${{ number_format($cartInsights['month']['total_cart_value'], 2) }} total value
                    </div>
                </div>
            </div>

            <!-- Shopping Habits -->
            <div class="bg-gradient-to-br from-orange-50 to-orange-100 border border-orange-200 rounded-xl p-4">
                <div class="flex items-center justify-between mb-2">
                    <h3 class="text-sm font-semibold text-orange-700">Shopping Habits</h3>
                    <i class="fas fa-clock text-orange-500"></i>
                </div>
                <div class="space-y-1">
                    <div class="text-2xl font-bold text-orange-800">{{ $cartInsights['month']['favorite_shopping_hour'] }}:00</div>
                    <div class="text-xs text-orange-600">Favorite Hour</div>
                    <div class="text-xs text-orange-600">
                        {{ $cartInsights['month']['avg_products_per_session'] }} products/session
                    </div>
                </div>
            </div>
        </div>

        <!-- Detailed Shopping Patterns -->
        @if(!empty($shoppingPatterns['favorite_shopping_hours']['distribution']))
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
            <!-- Shopping Hours Chart -->
            <div class="bg-gray-50 rounded-xl p-4">
                <h3 class="text-lg font-semibold text-gray-700 mb-4">Peak Shopping Hours</h3>
                <div class="space-y-2">
                    @php
                        $maxCount = max(array_values($shoppingPatterns['favorite_shopping_hours']['distribution']));
                    @endphp
                    @foreach($shoppingPatterns['favorite_shopping_hours']['distribution'] as $hour => $count)
                        <div class="flex items-center space-x-2">
                            <span class="text-sm font-medium text-gray-600 w-12">{{ $hour }}:00</span>
                            <div class="flex-1 bg-gray-200 rounded-full h-3">
                                <div class="bg-indigo-500 h-3 rounded-full" style="width: {{ ($count / $maxCount) * 100 }}%"></div>
                            </div>
                            <span class="text-xs text-gray-500 w-8">{{ $count }}</span>
                        </div>
                    @endforeach
                </div>
            </div>

            <!-- Shopping Behavior Score -->
            <div class="bg-gray-50 rounded-xl p-4">
                <h3 class="text-lg font-semibold text-gray-700 mb-4">Shopping Behavior Analysis</h3>
                <div class="space-y-4">
                    <div>
                        <div class="flex justify-between items-center mb-1">
                            <span class="text-sm font-medium text-gray-600">Behavior Score</span>
                            <span class="text-sm font-bold text-indigo-600">{{ $shoppingPatterns['shopping_behavior_score'] ?? 0 }}/100</span>
                        </div>
                        <div class="w-full bg-gray-200 rounded-full h-3">
                            <div class="bg-indigo-500 h-3 rounded-full" style="width: {{ $shoppingPatterns['shopping_behavior_score'] ?? 0 }}%"></div>
                        </div>
                    </div>
                    
                    @if(!empty($shoppingPatterns['conversion_patterns']))
                    <div class="grid grid-cols-2 gap-4 text-sm">
                        <div>
                            <span class="text-gray-600">Conversion Rate:</span>
                            <span class="font-semibold text-green-600">{{ $shoppingPatterns['conversion_patterns']['conversion_rate'] }}%</span>
                        </div>
                        <div>
                            <span class="text-gray-600">Cart Completion:</span>
                            <span class="font-semibold text-blue-600">{{ $shoppingPatterns['conversion_patterns']['completion_efficiency'] }}%</span>
                        </div>
                    </div>
                    @endif
                </div>
            </div>
        </div>
        @endif

        <!-- Personalized Recommendations -->
        <div class="bg-gradient-to-r from-indigo-50 to-purple-50 border border-indigo-200 rounded-xl p-4">
            <h3 class="text-lg font-semibold text-gray-700 mb-3">Personalized Shopping Insights</h3>
            <div class="space-y-2">
                @foreach($cartInsights['recommendations'] as $recommendation)
                <div class="flex items-start space-x-2">
                    <i class="fas fa-lightbulb text-yellow-500 mt-1"></i>
                    <p class="text-sm text-gray-700">{{ $recommendation }}</p>
                </div>
                @endforeach
            </div>
        </div>
        @else
        <!-- Empty State -->
        <div class="text-center py-12">
            <i class="fas fa-shopping-cart text-gray-300 text-6xl mb-4"></i>
            <h3 class="text-xl font-semibold text-gray-700 mb-2">No Shopping Data Yet</h3>
            <p class="text-gray-500 mb-4">Start shopping to see your personalized insights and analytics!</p>
            <p class="text-sm text-gray-400 mb-4">Or generate sample data to see how the analytics work:</p>
            <form action="{{ route('dashboard.generate-test-data') }}" method="POST" class="inline">
                @csrf
                <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-3 rounded-lg transition-colors shadow-md">
                    <i class="fas fa-magic mr-2"></i>Generate Test Shopping Data
                </button>
            </form>
        </div>
        @endif
    </div>

    <!-- ===== PRESERVED ORIGINAL CONTENT ===== -->
    
    <!-- Original Profile & Orders Section (Enhanced) -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div class="bg-white rounded-2xl shadow-lg p-6 flex flex-col items-center border-l-4 border-yellow-500">
            <div class="w-24 h-24 bg-gradient-to-br from-yellow-100 to-orange-100 text-yellow-800 flex items-center justify-center rounded-full text-3xl mb-4 shadow-inner">
                <i class="fas fa-user"></i>
            </div>
            <h2 class="text-xl font-semibold text-gray-800">{{ $user->name }}</h2>
            <p class="text-sm text-gray-500 mb-2">{{ $user->email }}</p>
            <p class="text-xs text-gray-400 mb-4">Total Spent: ${{ number_format($userStats['total_spent'], 2) }}</p>
            <a href="{{ route('profile.edit') }}" class="bg-yellow-600 hover:bg-yellow-700 text-white px-4 py-2 rounded-md text-sm transition-colors shadow-md">
                Edit Profile
            </a>
        </div>

        <!-- Enhanced Orders Table -->
        <div class="lg:col-span-2">
            <div class="bg-white rounded-2xl shadow-lg p-6 border-l-4 border-blue-500">
                <h2 class="text-xl font-bold text-gray-800 mb-4 flex items-center">
                    <i class="fas fa-shopping-cart text-blue-600 mr-2"></i>
                    Recent Orders
                </h2>
                <div class="overflow-x-auto">
                    <table class="w-full text-sm text-left border rounded-xl overflow-hidden">
                        <thead class="bg-gradient-to-r from-gray-50 to-gray-100 text-gray-600 uppercase text-xs">
                            <tr>
                                <th class="px-4 py-3">Order #</th>
                                <th class="px-4 py-3">Date</th>
                                <th class="px-4 py-3">Items</th>
                                <th class="px-4 py-3">Total</th>
                                <th class="px-4 py-3">Status</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-100">
                            @forelse($orders as $order)
                                <tr class="hover:bg-gray-50 transition-colors">
                                    <td class="px-4 py-3 font-medium text-blue-600">#{{ $order->OrderID }}</td>
                                    <td class="px-4 py-3">{{ \Carbon\Carbon::parse($order->OrderDate)->format('M d, Y') }}</td>
                                    <td class="px-4 py-3">{{ $order->items_summary ?? 'N/A' }}</td>
                                    <td class="px-4 py-3 font-semibold">Rs {{ number_format($order->SubTotal ?? 0, 2) }}</td>
                                    <td class="px-4 py-3">
                                        <span class="bg-green-100 text-green-800 text-xs font-semibold px-2 py-1 rounded-full">
                                            {{ $order->status ?? 'Pending' }}
                                        </span>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="5" class="px-4 py-8 text-gray-500 text-center">
                                        <i class="fas fa-shopping-bag text-gray-300 text-3xl mb-2"></i>
                                        <div>No orders found.</div>
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Enhanced Recommended Products (Original + AI) -->
    <div class="bg-white rounded-2xl shadow-lg p-6 border-l-4 border-green-500">
        <h2 class="text-2xl font-bold text-gray-800 mb-6 flex items-center">
            <i class="fas fa-star text-green-600 mr-3"></i>
            Product Recommendations
        </h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
            @forelse($recommended as $product)
                <div class="border border-gray-200 rounded-xl p-4 shadow hover:shadow-lg text-center transition-all duration-300 hover:scale-105">
                    <!-- Product Image with Fallback -->
                    <img src="{{ asset('images/uploads/'.$product->ProductID.'.png') }}" 
                         class="h-32 w-32 mx-auto mb-3 rounded-lg object-cover border-2 border-gray-100" 
                         onerror="this.src='{{ asset('images/placeholder.png') }}'">
                    <h3 class="font-semibold text-gray-800 mb-1">{{ $product->Name }}</h3>
                    <p class="text-lg font-bold text-green-600 mb-3">Rs {{ number_format($product->Price, 2) }}</p>
                    <button class="w-full bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 text-white px-4 py-2 rounded-lg text-sm transition-all duration-300 shadow-md hover:shadow-lg">
                        <i class="fas fa-cart-plus mr-1"></i>Add to Cart
                    </button>
                    <div class="text-xs text-gray-400 mt-2">MySQL Recommendation</div>
                </div>
            @empty
                <div class="col-span-full text-center py-12">
                    <i class="fas fa-box-open text-gray-300 text-6xl mb-4"></i>
                    <p class="text-gray-600 text-lg">No recommendations available right now.</p>
                    <p class="text-gray-400 text-sm mt-2">Check back later for personalized suggestions!</p>
                </div>
            @endforelse
        </div>
    </div>

</div>
@endsection
