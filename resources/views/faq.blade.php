@extends('layouts.public')

@section('title', 'FAQ - eBrew Café')

@section('content')
<section class="max-w-4xl mx-auto px-6 py-16">
    <h1 class="text-4xl font-bold text-center text-gray-900 mb-12">Frequently Asked Questions</h1>

    <div class="space-y-6">
        @foreach($faqs as $question => $answer)
            <div class="p-6 bg-white border-l-4 border-yellow-500 shadow hover:shadow-md rounded-md transition">
                <h2 class="text-lg sm:text-xl font-semibold text-gray-800 flex items-start">
                    <span class="text-yellow-500 text-2xl mr-3">❓</span> {{ $question }}
                </h2>
                <p class="text-gray-600 mt-2 text-sm sm:text-base leading-relaxed">{{ $answer }}</p>
            </div>
        @endforeach
    </div>
</section>
@endsection
