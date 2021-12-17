ARG DEBIAN_VERSION=bookworm
FROM debian:${DEBIAN_VERSION}

ENV DEBIAN_FRONTEND=noninteractive \
    PMA_DOCUMENT_ROOT=/var/www/html \
    PMA_VERSION=5.2.1

# Install Apache, PHP, and required PHP extensions
RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    php-mbstring \
    php-zip \
    php-gd \
    php-xml \
    php-mysql \
    php-json \
    wget \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Enable mod_rewrite and suppress ServerName warning
RUN a2enmod rewrite \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
    && echo "Listen 0.0.0.0:8080" > /etc/apache2/ports.conf \
    && sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8080>/' /etc/apache2/sites-available/000-default.conf

# Download and extract phpMyAdmin
RUN wget https://files.phpmyadmin.net/phpMyAdmin/${PMA_VERSION}/phpMyAdmin-${PMA_VERSION}-all-languages.zip \
    && unzip phpMyAdmin-${PMA_VERSION}-all-languages.zip -d /var/www \
    && mv /var/www/phpMyAdmin-${PMA_VERSION}-all-languages/* ${PMA_DOCUMENT_ROOT}/ \
    && rm -rf /var/www/phpMyAdmin-${PMA_VERSION}-all-languages* \
    && rm -f ${PMA_DOCUMENT_ROOT}/index.html

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set working directory
WORKDIR ${PMA_DOCUMENT_ROOT}

# Expose port 8080
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
