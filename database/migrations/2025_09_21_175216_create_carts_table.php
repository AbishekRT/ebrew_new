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
        Schema::create('carts', function (Blueprint $table) {
            $table->id(); // Standard Laravel id column
            $table->unsignedBigInteger('UserID')->nullable();
            $table->string('session_id')->nullable();
            
            // Foreign key constraint
            $table->foreign('UserID')->references('id')->on('users')->onDelete('cascade');
            
            // Indexes for performance
            $table->index(['UserID', 'session_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('carts');
    }
};
