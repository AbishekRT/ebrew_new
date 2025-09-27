# Use official PHP 8.2 image with necessary extensions
FROM php:8.2-cli

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions including MongoDB
RUN docker-php-ext-install pdo_mysql mbstring xml curl
RUN pecl install mongodb && docker-php-ext-enable mongodb

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Set working directory
WORKDIR /app

# Copy composer files
COPY composer.json composer.lock ./

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev --no-interaction

# Copy package files
COPY package.json package-lock.json ./

# Install Node dependencies and build assets
RUN npm ci --only=production && npm run build

# Copy application code
COPY . .

# Set permissions
RUN chmod -R 755 storage bootstrap/cache

# Expose port
EXPOSE $PORT

# Start command
CMD ["php", "-S", "0.0.0.0:$PORT", "-t", "public/"]