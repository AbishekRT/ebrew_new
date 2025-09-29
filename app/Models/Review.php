<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Review extends Model
{
    use HasFactory;

    protected $fillable = [
        'reviewable_id',
        'reviewable_type',
        'user_id',
        'rating',
        'title',
        'comment',
        'is_featured'
    ];

    /**
     * Get the attributes that should be cast.
     */
    protected function casts(): array
    {
        return [
            'rating' => 'integer',
            'is_featured' => 'boolean',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    // ========================
    // Polymorphic Relationships
    // ========================

    /**
     * Get the owning reviewable model (Item or Order).
     */
    public function reviewable()
    {
        return $this->morphTo();
    }

    /**
     * Get the user who created the review
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // ========================
    // Query Scopes
    // ========================

    /**
     * Scope to get featured reviews
     */
    public function scopeFeatured($query)
    {
        return $query->where('is_featured', true);
    }

    /**
     * Scope to get reviews by rating
     */
    public function scopeByRating($query, $rating)
    {
        return $query->where('rating', $rating);
    }

    /**
     * Scope to get high-rated reviews
     */
    public function scopeHighRated($query, $minRating = 4)
    {
        return $query->where('rating', '>=', $minRating);
    }

    /**
     * Scope to get recent reviews
     */
    public function scopeRecent($query, $days = 30)
    {
        return $query->where('created_at', '>=', now()->subDays($days));
    }

    // ========================
    // Accessors & Mutators
    // ========================

    /**
     * Get star rating display
     */
    public function getStarsAttribute()
    {
        return str_repeat('★', $this->rating) . str_repeat('☆', 5 - $this->rating);
    }

    /**
     * Check if review is recent
     */
    public function getIsRecentAttribute()
    {
        return $this->created_at >= now()->subWeeks(2);
    }

    /**
     * Get short comment
     */
    public function getShortCommentAttribute()
    {
        return Str::limit($this->comment, 100);
    }
}