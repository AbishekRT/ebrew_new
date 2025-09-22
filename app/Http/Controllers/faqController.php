<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class FaqController extends Controller
{
    public function index()
    {
        $faqs = [
            "How should I store my coffee to keep it fresh?" => "To maintain freshness, store your coffee in an airtight container in a cool, dry place away from direct sunlight. Avoid refrigerating or freezing your coffee as this can introduce moisture and affect the flavor. For optimal taste, buy coffee in smaller quantities and use within 2-3 weeks of the roast date.",
            
            "Is your coffee ground or whole bean?" => "We offer both ground and whole bean options. For the freshest taste, we recommend purchasing whole beans and grinding them just before brewing. However, if you prefer convenience, our pre-ground coffee is available in various grind sizes suitable for different brewing methods including espresso, drip coffee, French press, and pour-over.",
            
            "How long does your coffee stay fresh?" => "Our coffee is best consumed within 2 to 3 weeks of the roast date for optimal flavor and aroma. We roast our beans to order to ensure maximum freshness. Each bag is marked with a roast date so you can track freshness. While coffee doesn't expire in the traditional sense, its flavor profile will gradually diminish over time.",
            
            "What brewing method works best?" => "Our coffee is suitable for most brewing methods including espresso, drip coffee makers, French press, pour-over, AeroPress, and cold brew. Each method brings out different flavor characteristics. For espresso, we recommend our darker roasts, while our medium roasts work excellently for pour-over and drip methods.",
            
            "Are your coffee beans organic or fair trade?" => "Yes! We source our beans from ethical and sustainable farms that practice organic farming methods and fair trade principles. Our partnerships ensure farmers receive fair compensation for their high-quality beans. We're committed to supporting sustainable coffee growing practices that protect both the environment and farming communities.",
            
            "How long does shipping take?" => "Orders are usually processed within 1-2 business days and shipped via standard delivery which takes 3-5 business days. We also offer expedited shipping options including 2-day and overnight delivery for urgent orders. All orders over $50 qualify for free standard shipping. You'll receive a tracking number once your order ships.",
            
            "Do you offer subscriptions?" => "Yes, we offer flexible subscription plans that deliver fresh coffee to your door at regular intervals. Choose from weekly, bi-weekly, or monthly deliveries. Subscribers enjoy a 10% discount on all orders and can easily modify, pause, or cancel their subscription at any time through their account dashboard.",
            
            "Is your packaging eco-friendly?" => "We are committed to sustainability and use eco-friendly packaging materials whenever possible. Our coffee bags are made from recyclable materials with biodegradable valves. We're continuously working to reduce our environmental footprint by exploring new sustainable packaging options and minimizing waste in our operations."
        ];

        return view('faq', compact('faqs'));
    }
}
