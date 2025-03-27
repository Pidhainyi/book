FROM php:8.2-fpm-alpine

# Install only necessary PHP extensions
RUN apk add --no-cache \
    libpng-dev \
    freetype-dev \
    jpeg-dev \
    libzip-dev \
    postgresql-dev \
    oniguruma-dev \
    bash \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_pgsql pgsql mbstring exif pcntl bcmath opcache zip

# Set working directory
WORKDIR /var/www/html

# Create a non-root user
RUN addgroup -g 1000 www && adduser -u 1000 -G www -s /bin/sh -D www

# Copy application files and set correct permissions
COPY . /var/www/html
RUN chown -R www:www /var/www/html

# Switch to non-root user
USER www

# Expose port 9000 for PHP-FPM
EXPOSE 9000
CMD ["php-fpm"]