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
        Schema::create('cart_items', function (Blueprint $table) {
            $table->id('CartItemID');
            $table->unsignedBigInteger('CartID');
            $table->unsignedBigInteger('ItemID');
            $table->integer('Quantity')->default(1);
            
            // Foreign key constraints
            $table->foreign('CartID')->references('CartID')->on('carts')->onDelete('cascade');
            $table->foreign('ItemID')->references('id')->on('items')->onDelete('cascade');
            
            // Unique constraint to prevent duplicate items in same cart
            $table->unique(['CartID', 'ItemID']);
            
            // Indexes for performance
            $table->index('CartID');
            $table->index('ItemID');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cart_items');
    }
};
