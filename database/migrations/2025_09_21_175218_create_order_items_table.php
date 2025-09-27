<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('order_items', function (Blueprint $table) {
            $table->unsignedBigInteger('OrderID');
            $table->unsignedBigInteger('ItemID'); 
            $table->integer('Quantity');
            // Note: Price column will be added by later migration
            
            // Composite primary key
            $table->primary(['OrderID', 'ItemID']);
            
            // Foreign key constraints
            $table->foreign('OrderID')->references('OrderID')->on('orders')->onDelete('cascade');
            $table->foreign('ItemID')->references('ItemID')->on('items')->onDelete('cascade');
            
            // Indexes for performance
            $table->index('OrderID');
            $table->index('ItemID');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_items');
    }
};