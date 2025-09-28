#!/usr/bin/env php
<?php
// Simple test to check Item creation locally

require_once 'vendor/autoload.php';

use App\Models\Item;

// Test creating one item to check if our structure is correct
$testItem = [
    'Name' => 'Test Coffee',
    'Description' => 'Test description',
    'Price' => 25.99,
    'Image' => 'images/1.png',
    'TastingNotes' => 'Test notes',
    'ShippingAndReturns' => 'Test shipping',
    'RoastDates' => date('Y-m-d')
];

echo "Testing Item creation with structure:\n";
print_r($testItem);

echo "\nItem fillable fields:\n";
print_r((new Item())->getFillable());