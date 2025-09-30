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
        Schema::table('login_histories', function (Blueprint $table) {
            if (!Schema::hasColumn('login_histories', 'session_data')) {
                $table->json('session_data')->nullable()->after('failure_reason');
            }
            if (!Schema::hasColumn('login_histories', 'user_agent')) {
                $table->text('user_agent')->nullable()->change();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('login_histories', function (Blueprint $table) {
            if (Schema::hasColumn('login_histories', 'session_data')) {
                $table->dropColumn('session_data');
            }
        });
    }
};