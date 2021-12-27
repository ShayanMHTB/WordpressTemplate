# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WordPress Custom Image - Alpine Base
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ARG WORDPRESS_VERSION=latest

FROM alpine:3.19

# Install PHP and necessary packages
RUN apk add --no-cache \
    bash \
    curl \
    php82 \
    php82-fpm \
    php82-mysqli \
    php82-pdo_mysql \
    php82-gd \
    php82-curl \
    php82-zip \
    php82-xml \
    php82-mbstring \
    php82-json \
    php82-opcache \
    php82-session \
    php82-fileinfo \
    php82-tokenizer \
    mysql-client \
    && ln -sf /usr/bin/php82 /usr/bin/php

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.9.0/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Create WordPress user and directory
RUN addgroup -g 1000 wordpress \
    && adduser -D -s /bin/bash -G wordpress -u 1000 wordpress \
    && mkdir -p /var/www/html \
    && chown -R wordpress:wordpress /var/www/html

# Copy entrypoint
COPY images/wordpress/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set working directory
WORKDIR /var/www/html

# Switch to wordpress user
USER wordpress

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm82", "--nodaemonize"]
