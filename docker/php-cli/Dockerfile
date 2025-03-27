FROM php:8.2-cli-alpine

# Install system dependencies and development tools
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libzip-dev \
    postgresql-dev \
    oniguruma-dev \
    bash \
    make \
    nodejs \
    npm \
    yarn

# Install PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_pgsql \
    pgsql \
    mbstring \
    zip \
    gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Create a non-root user
RUN addgroup -g 1000 www && adduser -u 1000 -G www -s /bin/sh -D www

# Copy application files and set correct permissions
COPY --chown=www:www . /var/www/html

# Switch to non-root user
USER www

# Default to an interactive shell
CMD ["bash"]