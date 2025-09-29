# eBrew Laravel - Railway Production Deployment Fix

## Issues Identified & Solutions

### Issue 1: Missing Sessions Table
**Error:** `SQLSTATE[42S02]: Base table or view not found: 1146 Table 'railway.sessions' doesn't exist`

**Root Cause:** Production environment uses `SESSION_DRIVER=database` but sessions table doesn't exist in Railway MySQL database.

**Solution:**
- Created migration: `database/migrations/2025_09_29_000000_create_sessions_table.php`
- Updated Railway configuration to use database sessions
- Added sessions table creation to deployment script

### Issue 2: Broken Route References
**Error:** `Route [items.index] not defined`

**Root Cause:** Header template references non-existent `items.index` route.

**Solution:**
- Updated `resources/views/partials/header.blade.php` to use correct `products.index` route
- All navigation links now point to existing routes

### Issue 3: Database Configuration Mismatch
**Root Cause:** Local development uses `ebrew_laravel_db` but Railway production uses `railway` database.

**Solution:**
- Created separate `.env.railway` for production deployment
- Updated Railway environment variables to match
- Added proper database migration handling in deployment

### Issue 4: Livewire Component Error Handling
**Root Cause:** CartCounter component logs excessively in production and lacks proper error handling.

**Solution:**
- Added environment-aware logging (only logs in development)
- Improved error handling with null coalescing
- Added fallback mechanisms for database connection failures

## Files Modified

### 1. Environment Configuration
- `.env` - Restored for local development
- `.env.railway` - New file for Railway production
- `railway.toml` - Updated with proper deployment configuration

### 2. Database Migrations
- `database/migrations/2025_09_29_000000_create_sessions_table.php` - New sessions table

### 3. View Templates
- `resources/views/partials/header.blade.php` - Fixed route references

### 4. Application Components
- `app/Livewire/CartCounter.php` - Improved error handling and logging

### 5. Deployment Files
- `deploy.sh` - New Railway deployment script

## Railway Environment Variables Required

Copy these exact variables to your Railway web service:

```env
APP_NAME="eBrew"
APP_ENV="production"
APP_KEY="base64:aDUI1YE7uvxmjzym/fsIk1TRgcc3Zv4h81tCqdepuvE="
APP_DEBUG="false"
APP_URL="https://web-production-68199a.up.railway.app/"
APP_LOCALE="en"
APP_FALLBACK_LOCALE="en"
APP_FAKER_LOCALE="en_US"
APP_MAINTENANCE_DRIVER="file"
PHP_CLI_SERVER_WORKERS="4"
BCRYPT_ROUNDS="12"
LOG_CHANNEL="stack"
LOG_STACK="single"
LOG_DEPRECATIONS_CHANNEL="null"
LOG_LEVEL="debug"
DB_CONNECTION="mysql"
DB_HOST="mysql.railway.internal"
DB_PORT="3306"
DB_DATABASE="railway"
DB_USERNAME="root"
DB_PASSWORD="LlvoGAKttnOCmRkXQDSbPPYKUgYWZajz"
MONGO_DB_CONNECTION="mongodb"
MONGO_DB_URI="mongodb+srv://abhishakeshanaka_db_user:asiri123@ebrewapi.r7gfad9.mongodb.net/ebrew_api?retryWrites=true&w=majority&appName=ebrewAPI"
MONGO_DB_DATABASE="ebrew_api"
MONGO_DB_USERNAME="abhishakeshanaka_db_user"
MONGO_DB_PASSWORD="asiri123"
MONGO_DB_AUTH_DATABASE="admin"
SESSION_DRIVER="database"
SESSION_LIFETIME="120"
SESSION_ENCRYPT="false"
SESSION_PATH="/"
SESSION_DOMAIN="null"
CACHE_STORE="file"
QUEUE_CONNECTION="database"
BROADCAST_CONNECTION="log"
FILESYSTEM_DISK="local"
MEMCACHED_HOST="127.0.0.1"
REDIS_CLIENT="phpredis"
REDIS_HOST="127.0.0.1"
REDIS_PASSWORD="null"
REDIS_PORT="6379"
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
AWS_DEFAULT_REGION="us-east-1"
AWS_BUCKET=""
AWS_USE_PATH_STYLE_ENDPOINT="false"
VITE_APP_NAME="${APP_NAME}"
VITE_DEV_SERVER_URL=""
```

## Deployment Steps

1. **Commit all changes to your repository:**
   ```bash
   git add .
   git commit -m "Fix Railway production deployment issues"
   git push origin main
   ```

2. **Deploy to Railway:**
   - Railway will automatically trigger deployment
   - The `deploy.sh` script will run during build
   - Database migrations will be executed
   - Sessions table will be created

3. **Verify deployment:**
   - Visit: https://web-production-68199a.up.railway.app/
   - Test FAQ page: https://web-production-68199a.up.railway.app/faq
   - Test registration: https://web-production-68199a.up.railway.app/register

## Expected Results

After deployment, the following should work:

✅ **FAQ page** - No more 500 errors, displays FAQ content correctly
✅ **Registration** - Users can register and login successfully
✅ **Sessions** - Proper session handling with database storage
✅ **Navigation** - All header links work correctly
✅ **Cart functionality** - Livewire cart counter works without errors
✅ **Database operations** - MySQL and MongoDB connections stable

## Local Development

For local development, use the standard Laravel commands:

```bash
# Install dependencies
composer install
npm install

# Setup environment
cp .env.example .env
php artisan key:generate

# Run migrations
php artisan migrate

# Start development server
php artisan serve
npm run dev
```

The local `.env` file is configured for local MySQL (`ebrew_laravel_db`) while Railway uses the separate `.env.railway` configuration.