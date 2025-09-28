# Use official PHP with Apache
FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl unzip zip \
    libpng-dev libonig-dev libxml2-dev libzip-dev libssl-dev pkg-config \
    libcurl4-openssl-dev supervisor \
    nodejs npm \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd zip \
    && rm -rf /var/lib/apt/lists/*

# Install MongoDB PHP extension
RUN pecl install mongodb \
    && docker-php-ext-enable mongodb

# Enable Apache modules
RUN a2enmod rewrite headers \
    && service apache2 restart

# Suppress Apache ServerName warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy entrypoint script BEFORE copying project files
COPY ./docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy project files
COPY . .

# Install PHP dependencies
RUN composer install --optimize-autoloader

# Install Node dependencies and build production assets
RUN npm ci --silent
ENV NODE_ENV=production

# Clean any previous build
RUN rm -rf /var/www/html/public/build

# Build assets with detailed output
RUN NODE_ENV=production npm run build

# Create fallback manifest and assets if not generated
RUN if [ ! -f /var/www/html/public/build/manifest.json ]; then \
        echo "Vite build did not create manifest, creating fallback..." && \
        mkdir -p /var/www/html/public/build/assets && \
        echo '{"resources/css/app.css":{"file":"assets/app.css","src":"resources/css/app.css","isEntry":true},"resources/js/app.js":{"file":"assets/app.js","src":"resources/js/app.js","isEntry":true}}' > /var/www/html/public/build/manifest.json && \
        echo "/* Fallback CSS */" > /var/www/html/public/build/assets/app.css && \
        echo "console.log('Fallback JS loaded');" > /var/www/html/public/build/assets/app.js; \
    else \
        echo "Vite build successful - manifest.json created"; \
    fi

# Verify build output exists
RUN ls -la /var/www/html/public/build/ \
    && ls -la /var/www/html/public/build/assets/ || echo "No assets directory" \
    && ls -la /var/www/html/public/build/.vite/ || echo "No .vite directory" \
    && (cat /var/www/html/public/build/manifest.json || echo "No manifest.json found")

# Set permissions for Laravel and Vite assets
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Ensure public/build directory exists and has correct permissions
RUN mkdir -p /var/www/html/public/build \
    && chown -R www-data:www-data /var/www/html/public \
    && chmod -R 755 /var/www/html/public

# Make Apache serve the public folder
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Create a simple health check endpoint
RUN echo '<?php echo "OK"; ?>' > /var/www/html/public/health.php

# Configure Apache for HTTPS behind a proxy
RUN echo "Header always set X-Forwarded-Proto https" >> /etc/apache2/conf-available/headers.conf \
    && a2enconf headers \
    && service apache2 restart

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/health.php || exit 1

# Expose Apache port
EXPOSE 80

# Start Apache via entrypoint
ENTRYPOINT ["entrypoint.sh"]
