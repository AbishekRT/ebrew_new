#!/bin/bash
echo "Running database migration and seeding on Railway..."

# This command will be run on Railway to restore the product data
php artisan migrate:fresh --seed --force

echo "Migration and seeding completed!"