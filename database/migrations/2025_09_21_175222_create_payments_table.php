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
        Schema::create('payments', function (Blueprint $table) {
            $table->id('PaymentID');
            $table->unsignedBigInteger('OrderID');
            $table->decimal('Amount', 10, 2);
            $table->string('PaymentMethod', 50);
            $table->string('PaymentStatus', 20)->default('pending');
            $table->timestamp('PaymentDate');
            $table->string('TransactionID')->nullable();
            
            // Foreign key constraint
            $table->foreign('OrderID')->references('OrderID')->on('orders')->onDelete('cascade');
            
            // Indexes for performance
            $table->index('OrderID');
            $table->index('PaymentStatus');
            $table->index('PaymentDate');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};