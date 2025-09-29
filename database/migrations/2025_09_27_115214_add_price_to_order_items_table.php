<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

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
        
        // Update existing order_items with current item prices (SQLite compatible)
        DB::statement('
            UPDATE order_items 
            SET Price = (
                SELECT items.Price 
                FROM items 
                WHERE items.id = order_items.ItemID
            )
            WHERE order_items.Price IS NULL
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
