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
        Schema::create('items', function (Blueprint $table) {
            $table->id(); // Standard Laravel id column
            $table->string('Name');
            $table->text('Description');
            $table->decimal('Price', 10, 2);
            $table->string('Image')->nullable();
            $table->text('TastingNotes')->nullable();
            $table->text('ShippingAndReturns')->nullable();
            $table->date('RoastDates')->nullable();
            
            // Indexes for performance
            $table->index('Name');
            $table->index('Price');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('items');
    }
};
