<?php

namespace App\Collections;

use Illuminate\Database\Eloquent\Collection;

class ItemCollection extends Collection
{
    /**
     * Get items grouped by price range
     */
    public function groupByPriceRange(): array
    {
        return $this->groupBy(function ($item) {
            if ($item->Price < 1000) {
                return 'budget';
            } elseif ($item->Price < 2500) {
                return 'mid-range';
            } else {
                return 'premium';
            }
        })->toArray();
    }

    /**
     * Get statistical analysis of prices
     */
    public function getPriceStatistics(): array
    {
        $prices = $this->pluck('Price');
        
        return [
            'count' => $prices->count(),
            'min' => $prices->min(),
            'max' => $prices->max(),
            'average' => round($prices->avg(), 2),
            'median' => $this->getMedian($prices->sort()->values()),
            'total_value' => $prices->sum()
        ];
    }

    /**
     * Filter items by multiple criteria
     */
    public function filterAdvanced(array $filters): self
    {
        return $this->filter(function ($item) use ($filters) {
            // Price range filter
            if (isset($filters['price_min']) && $item->Price < $filters['price_min']) {
                return false;
            }
            if (isset($filters['price_max']) && $item->Price > $filters['price_max']) {
                return false;
            }
            
            // Search in name, description, or tasting notes
            if (isset($filters['search'])) {
                $search = strtolower($filters['search']);
                $searchableText = strtolower(
                    $item->Name . ' ' . $item->Description . ' ' . $item->TastingNotes
                );
                if (strpos($searchableText, $search) === false) {
                    return false;
                }
            }
            
            // Premium filter
            if (isset($filters['is_premium']) && $filters['is_premium']) {
                if (!$item->is_premium) {
                    return false;
                }
            }
            
            return true;
        });
    }

    /**
     * Get items suitable for gift recommendations
     */
    public function getGiftRecommendations(int $budget = 3000): self
    {
        return $this->filter(function ($item) use ($budget) {
            return $item->Price <= $budget && $item->Price >= 1500; // Sweet spot for gifts
        })->sortBy('Price');
    }

    /**
     * Get trending items based on recent orders
     */
    public function getTrending(int $limit = 5): self
    {
        return $this->sortByDesc(function ($item) {
            // This would typically look at recent order data
            // For now, use a simple calculation based on price and availability
            return $item->orderItems->count() * ($item->Price / 1000);
        })->take($limit);
    }

    /**
     * Generate product recommendations based on user preferences
     */
    public function getRecommendations(array $userPreferences = []): self
    {
        $priceRange = $userPreferences['price_preference'] ?? 'all';
        $categories = $userPreferences['categories'] ?? [];
        
        return $this->filter(function ($item) use ($priceRange, $categories) {
            // Filter by price preference
            switch ($priceRange) {
                case 'budget':
                    if ($item->Price >= 1500) return false;
                    break;
                case 'mid':
                    if ($item->Price < 1500 || $item->Price > 3000) return false;
                    break;
                case 'premium':
                    if ($item->Price <= 3000) return false;
                    break;
            }
            
            return true;
        })->shuffle()->take(6);
    }

    /**
     * Calculate median value
     */
    private function getMedian($sortedCollection): float
    {
        $count = $sortedCollection->count();
        
        if ($count % 2 === 0) {
            $middle1 = $sortedCollection->get(($count / 2) - 1);
            $middle2 = $sortedCollection->get($count / 2);
            return ($middle1 + $middle2) / 2;
        } else {
            return $sortedCollection->get(floor($count / 2));
        }
    }

    /**
     * Export collection data for external systems
     */
    public function export(string $format = 'array'): array
    {
        $data = $this->map(function ($item) {
            return [
                'id' => $item->ItemID,
                'name' => $item->Name,
                'price' => $item->Price,
                'formatted_price' => $item->formatted_price,
                'is_premium' => $item->is_premium,
                'image_url' => $item->image_url,
                'short_description' => $item->short_description
            ];
        });

        switch ($format) {
            case 'json':
                return json_encode($data);
            case 'csv':
                // Would implement CSV export logic here
                return $data->toArray();
            default:
                return $data->toArray();
        }
    }
}