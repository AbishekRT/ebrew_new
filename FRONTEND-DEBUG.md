# Frontend Assets Debug Guide

## Check if your Rails app frontend is loading correctly:

1. **Access your Railway app URL** and check browser developer tools (F12)

2. **Look for 404 errors** in the Console/Network tabs for:

    - `/build/assets/app-[hash].css`
    - `/build/assets/app-[hash].js`
    - `/build/manifest.json`

3. **Quick fixes to try:**

    **🔄 Hard Refresh**: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)

    **🕵️ Check build directory**:
    Access: `https://your-railway-url.railway.app/build/manifest.json`

    If you get 404, the build didn't work properly.

4. **If assets are still not loading**, the issue might be:
    - Vite build failed during Docker build
    - `public/build/` directory is empty
    - Apache permissions issue

## Temporary CSS fix (if needed):

Add this to your layout file to verify backend is working:

```html
<style>
    body {
        font-family: Arial, sans-serif;
        background: #f5f5f5;
        padding: 20px;
    }
    .container {
        max-width: 1200px;
        margin: 0 auto;
        background: white;
        padding: 20px;
        border-radius: 8px;
    }
</style>
```

This will give you basic styling while we fix the Vite build issue.
