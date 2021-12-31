# WordPress Docker Image
# Builds a minimal WordPress environment with PHP 8.2 on Debian base

FROM debian:bullseye-slim

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install core packages and add Sury PHP repository
RUN apt-get update && apt-get install -y \
    # Core system packages
    ca-certificates \
    curl \
    wget \
    unzip \
    gnupg2 \
    lsb-release \
    apt-transport-https \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add Sury PHP repository for latest stable PHP 8.2
RUN curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && apt-get update

# Install PHP 8.2 and required extensions for WordPress
RUN apt-get install -y \
    php8.2 \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-xmlrpc \
    php8.2-zip \
    php8.2-opcache \
    php8.2-intl \
    php8.2-bcmath \
    php8.2-soap \
    php8.2-imagick \
    php8.2-readline \
    php8.2-common \
    # Additional useful tools
    default-mysql-client \
    less \
    vim \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create www-data user directories and set permissions
RUN mkdir -p /var/www/html /var/www/.wp-cli/cache /var/log/php /run/php \
    && chown -R www-data:www-data /var/www/html /var/www/.wp-cli /var/log/php /run/php \
    && chmod -R 755 /var/www/html

# Install WP-CLI with correct URL
RUN curl -f -L -o wp-cli.phar https://github.com/wp-cli/wp-cli/releases/download/v2.9.0/wp-cli-2.9.0.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && chown www-data:www-data /usr/local/bin/wp

# Install Composer (for PHP dependency management)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chown www-data:www-data /usr/local/bin/composer

# Configure PHP 8.2 for WordPress
RUN sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/' /etc/php/8.2/fpm/php.ini \
    && sed -i 's/post_max_size = 8M/post_max_size = 64M/' /etc/php/8.2/fpm/php.ini \
    && sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php/8.2/fpm/php.ini \
    && sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/8.2/fpm/php.ini \
    && sed -i 's/max_input_vars = 1000/max_input_vars = 3000/' /etc/php/8.2/fpm/php.ini

# Configure PHP-FPM to listen on port 8000 and set log path
RUN sed -i 's/listen = \/run\/php\/php8.2-fpm.sock/listen = 0.0.0.0:8000/' /etc/php/8.2/fpm/pool.d/www.conf \
    && sed -i 's/;listen.allowed_clients = 127.0.0.1/listen.allowed_clients = any/' /etc/php/8.2/fpm/pool.d/www.conf \
    && sed -i 's|error_log = /var/log/php8.2-fpm.log|error_log = /var/log/php/php8.2-fpm.log|' /etc/php/8.2/fpm/php-fpm.conf

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set working directory
WORKDIR /var/www/html

# Create uploads directory and set permissions
RUN mkdir -p /var/www/html/wp-content/uploads \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose PHP-FPM port 8000
EXPOSE 8000

# Switch to www-data user
USER www-data

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command starts PHP-FPM 8.2
CMD ["php-fpm8.2", "--nodaemonize"]
