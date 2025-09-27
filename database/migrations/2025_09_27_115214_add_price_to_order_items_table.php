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
        Schema::table('order_items', function (Blueprint $table) {
            $table->decimal('Price', 10, 2)->nullable()->after('Quantity');
        });
        
        // Update existing order_items with current item prices
        \DB::statement('
            UPDATE order_items oi
            INNER JOIN items i ON oi.ItemID = i.ItemID 
            SET oi.Price = i.Price 
            WHERE oi.Price IS NULL
        ');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('order_items', function (Blueprint $table) {
            $table->dropColumn('Price');
        });
    }
};