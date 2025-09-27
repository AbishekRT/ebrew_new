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
        Schema::create('reviews', function (Blueprint $table) {
            $table->id();
            $table->morphs('reviewable'); // Creates reviewable_type, reviewable_id, and index automatically
            $table->unsignedBigInteger('user_id');
            $table->tinyInteger('rating')->unsigned()->default(5);
            $table->string('title')->nullable();
            $table->text('comment')->nullable();
            $table->boolean('is_featured')->default(false);
            $table->timestamps();

            // Other indexes
            $table->index('rating');
            $table->index('is_featured');

            // Foreign key constraint
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};