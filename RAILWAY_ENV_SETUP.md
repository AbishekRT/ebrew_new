## Railway Environment Variables Setup

Copy and paste these environment variables into your Railway project dashboard:

### Required Environment Variables:

```bash
APP_ENV=production
APP_DEBUG=false
APP_URL=https://web-production-68199a.up.railway.app
ASSET_URL=https://web-production-68199a.up.railway.app

# Database (update with your Railway MySQL credentials)
DATABASE_URL=mysql://root:password@host:port/database

# Or individual DB settings:
DB_CONNECTION=mysql
DB_HOST=your-mysql-host
DB_PORT=3306
DB_DATABASE=your-database-name
DB_USERNAME=your-username
DB_PASSWORD=your-password

# Optional but recommended:
LOG_LEVEL=info
SESSION_SECURE_COOKIE=true
SANCTUM_STATEFUL_DOMAINS=web-production-68199a.up.railway.app
```

### Steps:
1. Go to your Railway project dashboard
2. Click on your service
3. Go to "Variables" tab
4. Add each environment variable above
5. Deploy your app

### Important Notes:
- Replace `web-production-68199a.up.railway.app` with your actual Railway domain
- Make sure APP_URL and ASSET_URL both use `https://`
- Update database credentials to match your Railway MySQL service