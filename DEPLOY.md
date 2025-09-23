# eBrew Café - Laravel Application

## Deploy to Render

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/AbishekRT/ebrew_new)

## Manual Deployment Steps

1. **Fork this repository** to your GitHub account
2. **Sign up at [Render](https://render.com)** and connect your GitHub
3. **Create a new Web Service** and select your forked repository
4. **Configure the service:**
   - Environment: PHP
   - Build Command: `bash render-build.sh`
   - Start Command: `bash render-start.sh`

5. **Add Environment Variables:**
   ```
   APP_NAME=eBrew Café
   APP_ENV=production
   APP_DEBUG=false
   APP_KEY=[Generate new key]
   LOG_CHANNEL=stderr
   SESSION_DRIVER=database
   CACHE_DRIVER=database
   DB_CONNECTION=mysql
   DB_HOST=[Your MySQL host]
   DB_DATABASE=[Your database name]
   DB_USERNAME=[Your database user]
   DB_PASSWORD=[Your database password]
   ```

6. **Deploy!** Your application will be available at `https://your-service-name.onrender.com`

## Features Included

- ☕ Complete Coffee Shop E-commerce System
- 🛒 Shopping Cart with Livewire Components
- 👤 User Authentication & Registration
- 📦 Order Management System
- 🎨 Beautiful Tailwind CSS Design
- 📱 Fully Responsive Layout
- 🔒 Secure Checkout Process

## Technology Stack

- **Backend:** Laravel 12, PHP 8.4
- **Frontend:** Livewire, Tailwind CSS
- **Database:** MySQL
- **Authentication:** Laravel Jetstream + Sanctum
- **Hosting:** Render (Free Tier)

---

**Developed with ❤️ for coffee lovers everywhere!**