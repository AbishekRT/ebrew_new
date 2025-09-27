# syntax=docker/dockerfile:1

###################
# Stage 1: Node builder (optional for frontend)
###################
FROM node:20 AS node_builder
WORKDIR /build
COPY package*.json ./
RUN npm ci --silent
COPY . .
RUN npm run build --if-present

###################
# Stage 2: Composer (install PHP deps)
###################
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --prefer-dist
COPY . .
RUN composer dump-autoload --optimize

###################
# Stage 3: Production image (PHP built-in server)
###################
FROM php:8.3-fpm-bullseye

# Install OS packages and PHP extensions
RUN apt-get update && apt-get install -y \
    zip unzip git curl libpng-dev libonig-dev libxml2-dev libjpeg-dev libfreetype6-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install pdo_mysql mbstring bcmath gd xml zip opcache \
 && pecl install mongodb \
 && docker-php-ext-enable mongodb \
 && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www/html

# Copy composer + app
COPY --from=vendor /app /var/www/html

# Copy built frontend assets
COPY --from=node_builder /build/public /var/www/html/public

# Storage & cache permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
 && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

# Copy entrypoint script
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose Railway port
EXPOSE 8080
ENV PORT=8080

# Run entrypoint
CMD ["/usr/local/bin/entrypoint.sh"]
