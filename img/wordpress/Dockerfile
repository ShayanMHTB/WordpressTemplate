# Use an ARG to optionally override Debian version
ARG DEBIAN_VERSION=bookworm
FROM debian:${DEBIAN_VERSION}

# Set environment variables
ENV APACHE_DOCUMENT_ROOT=/var/www/html \
    WORDPRESS_DIR=/var/www/html \
    DEBIAN_FRONTEND=noninteractive \
    PATH="$PATH:/var/www/html/vendor/bin"

# Update and install packages
RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-zip \
    php-soap \
    php-intl \
    php-bcmath \
    php-cli \
    php-common \
    php-json \
    php-opcache \
    php-readline \
    curl \
    unzip \
    wget \
    git \
    vim \
    less \
    openssl \
    ca-certificates \
    libapache2-mod-php \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Suppress Apache "ServerName" warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Set up Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create the WordPress directory (bind mount expected to override this)
RUN mkdir -p ${WORDPRESS_DIR} && chown -R www-data:www-data ${WORDPRESS_DIR}

# Set working directory
WORKDIR ${WORDPRESS_DIR}

# Expose port 80 for Apache
EXPOSE 80

# Start via entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
