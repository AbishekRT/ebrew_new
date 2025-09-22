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
            
            "Is your packaging eco-friendly?" => "We are committed to sustainability and use eco-friendly packaging materials whenever possible. Our coffee bags are made from recyclable materials with biodegradable valves. We're continuously working to reduce our environmental footprint by exploring new sustainable packaging options and minimizing waste in our operations.",

            "What roast levels do you offer?" => "We offer light, medium, medium-dark, and dark roast profiles. Light roasts highlight origin characteristics and bright acidity, medium roasts provide balanced flavor, medium-dark roasts offer fuller body with some roast character, and dark roasts deliver bold, smoky flavors. Each roast level is carefully crafted to bring out the best in our premium beans.",

            "Do you accept returns or exchanges?" => "We stand behind our coffee quality. If you're not satisfied with your purchase, we offer a 30-day satisfaction guarantee. Contact our customer service team within 30 days of purchase for returns or exchanges. We'll provide a full refund or exchange for unopened bags, and we'll work with you on opened products to ensure your satisfaction.",

            "Can I visit your roastery?" => "Absolutely! We love sharing our passion for coffee. Our roastery offers guided tours every Saturday at 10 AM and 2 PM. You'll learn about our roasting process, cup different coffees, and see our equipment in action. Tours are free but require advance booking through our website or by calling our customer service team.",

            "What payment methods do you accept?" => "We accept all major credit cards (Visa, MasterCard, American Express, Discover), PayPal, Apple Pay, Google Pay, and bank transfers. For wholesale orders, we also offer net payment terms to qualified businesses. All transactions are processed securely through encrypted payment systems to protect your financial information.",

            "Do you offer wholesale pricing?" => "Yes, we offer competitive wholesale pricing for cafés, restaurants, offices, and retail stores. Our wholesale program includes volume discounts, custom roasting profiles, private labeling options, and dedicated account management. Minimum order quantities apply. Contact our wholesale team for a personalized quote and program details.",

            "How do I track my order?" => "Once your order ships, you'll receive an email with tracking information and a link to monitor your package's progress. You can also track orders by logging into your account on our website and viewing your order history. If you have any issues with tracking, our customer service team is happy to help locate your shipment.",

            "What's your caffeine content?" => "Caffeine content varies by bean origin and roast level. On average, our coffee contains 95-200mg of caffeine per 8oz cup. Light roasts typically have slightly more caffeine than dark roasts. We also offer decaffeinated options processed using the Swiss Water method, which removes 99.9% of caffeine while preserving flavor compounds."
        ];

        return view('faq', compact('faqs'));
    }
}
