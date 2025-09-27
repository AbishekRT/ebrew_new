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
        Schema::create('orders', function (Blueprint $table) {
            $table->id('OrderID');
            $table->unsignedBigInteger('UserID');
            $table->timestamp('OrderDate');
            $table->decimal('SubTotal', 10, 2);
            
            // Foreign key constraint
            $table->foreign('UserID')->references('id')->on('users')->onDelete('cascade');
            
            // Indexes for performance
            $table->index('OrderDate');
            $table->index('UserID');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};