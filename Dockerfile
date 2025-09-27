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

# Enable Apache mod_rewrite
RUN a2enmod rewrite

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

# Build assets with verbose output
RUN npm run build -- --mode production

# Verify build output exists and show contents
RUN ls -la /var/www/html/public/build/ && cat /var/www/html/public/build/manifest.json

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

# Expose Apache port
EXPOSE 80

# Start Apache via entrypoint
ENTRYPOINT ["entrypoint.sh"]