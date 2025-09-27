# ------------------------
# Stage 1: PHP dependencies
# ------------------------
FROM composer:2 AS vendor

WORKDIR /app

# Copy composer files
COPY composer.json composer.lock ./

# Install PHP dependencies (without dev for production)
RUN composer install --no-dev --optimize-autoloader --no-scripts --prefer-dist


# ------------------------
# Stage 2: Node build (if using Vite / Mix)
# ------------------------
FROM node:20 AS frontend

WORKDIR /app

COPY package.json package-lock.json* ./

RUN npm install

COPY . .

# Build frontend (if using Vite or Mix)
RUN npm run build


# ------------------------
# Stage 3: Final Image
# ------------------------
FROM php:8.2-fpm

# Install required extensions
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip unzip git curl \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd \
    && rm -rf /var/lib/apt/lists/*

# Install Nginx
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

# Configure PHP
COPY --from=vendor /app/vendor /var/www/html/vendor
COPY --from=frontend /app/public /var/www/html/public

# Copy app source
COPY . /var/www/html

WORKDIR /var/www/html

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

# Nginx default config (no custom file needed)
RUN echo 'server { \
    listen 80; \
    index index.php index.html; \
    server_name _; \
    root /var/www/html/public; \
    location / { try_files $uri $uri/ /index.php?$query_string; } \
    location ~ \.php$$ { \
        include snippets/fastcgi-php.conf; \
        fastcgi_pass 127.0.0.1:9000; \
        fastcgi_index index.php; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
        include fastcgi_params; \
    } \
    location ~ /\.ht { deny all; } \
}' > /etc/nginx/sites-available/default

EXPOSE 80

# Start services (php-fpm + nginx)
CMD service php8.2-fpm start && nginx -g "daemon off;"
