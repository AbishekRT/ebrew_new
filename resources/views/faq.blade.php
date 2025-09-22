@extends('layouts.public')

@section('title', 'FAQ - eBrew Café')

@section('content')
<section class="max-w-4xl mx-auto px-6 py-16">
    <h1 class="text-4xl font-bold text-center text-gray-900 mb-12">Frequently Asked Questions</h1>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        @foreach($faqs as $question => $answer)
            <div class="p-6 bg-white border-l-4 border-yellow-500 shadow hover:shadow-md rounded-md transition h-fit">
                <h2 class="text-lg font-semibold text-gray-800 flex items-start mb-3">
                    <span class="text-yellow-500 text-xl mr-2 flex-shrink-0">❓</span> 
                    <span class="leading-tight">{{ $question }}</span>
                </h2>
                <p class="text-gray-600 text-sm leading-relaxed">{{ $answer }}</p>
            </div>
        @endforeach
    </div>
</section>
@endsection
