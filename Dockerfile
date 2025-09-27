# ------------------------
# Stage 1: Node build (assets)
# ------------------------
FROM node:20 AS frontend

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install
COPY . .
RUN npm run build


# ------------------------
# Stage 2: PHP build
# ------------------------
FROM php:8.2-fpm

# Install system packages + PHP extensions
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip unzip git curl \
    && pecl install mongodb \
    && docker-php-ext-enable mongodb \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy project files
COPY . .

# Install PHP deps AFTER extensions are installed
RUN composer install --no-dev --optimize-autoloader --no-scripts --prefer-dist

# Copy frontend build output
COPY --from=frontend /app/public /var/www/html/public

# Permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

# Expose port for Railway
EXPOSE 8080
ENV PORT=8080

CMD ["php-fpm"]
