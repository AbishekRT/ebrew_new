<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class FaqController extends Controller
{
    public function index()
    {
        $faqs = [
            "How should I store my coffee to keep it fresh?" => "To maintain freshness, store your coffee in an airtight container...",
            "Is your coffee ground or whole bean?" => "We offer both ground and whole bean options...",
            "How long does your coffee stay fresh?" => "Our coffee is best consumed within 2 to 3 weeks...",
            "What brewing method works best?" => "Our coffee is suitable for most brewing methods...",
            "Are your coffee beans organic or fair trade?" => "Yes! We source our beans from ethical and sustainable farms...",
            "How long does shipping take?" => "Orders are usually processed within 1-2 business days...",
            "Do you offer subscriptions?" => "Yes, we offer flexible subscription plans...",
            "Is your packaging eco-friendly?" => "We are committed to sustainability..."
        ];

        return view('faq', compact('faqs'));
    }
}
