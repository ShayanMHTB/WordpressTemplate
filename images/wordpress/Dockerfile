# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃  WordPress on Debian with Apache + PHP 8.3 + wp-cli         ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# ⚙️ Add Sury repo for PHP 8.3 (Debian stable ships 8.2)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg lsb-release tzdata \
 && curl -fsSL https://packages.sury.org/php/README.txt >/dev/null \
 && curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-php.gpg \
 && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/sury-php.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    apache2 php8.3 libapache2-mod-php8.3 \
    php8.3-mysql php8.3-xml php8.3-gd php8.3-mbstring php8.3-zip php8.3-curl php8.3-intl php8.3-opcache \
    php8.3-imagick unzip less nano tini \
 && rm -rf /var/lib/apt/lists/*

# 🕒 Timezone inside container (overridable via .env TZ)
ENV TZ=UTC

# 🛠 Apache listen on 8000 (not 80) to avoid conflicts
RUN sed -i 's/80/8000/g' /etc/apache2/ports.conf \
 && sed -i 's/:80>/:8000>/g' /etc/apache2/sites-available/000-default.conf

# 📦 Install wp-cli
RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
 && chmod +x /usr/local/bin/wp

# 🏠 Document root
WORKDIR /var/www/html

# 🏁 Custom entrypoint for first-run WP setup
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8000

# Enable useful Apache modules
RUN a2enmod rewrite expires headers

# 🔐 Keep Apache in foreground; entrypoint will prep WordPress then launch
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["apachectl", "-D", "FOREGROUND"]
