#!/usr/bin/env bash
set -euo pipefail

# ───────────────────────────────────────────────────────────────
#  WordPress first-run:
#   • Download core if volume empty
#   • Generate wp-config.php from env
#   • Install site via wp-cli (optional)
#   • Then start Apache
# ───────────────────────────────────────────────────────────────

# Required DB vars
: "${DB_HOST:?Missing DB_HOST}"
: "${DB_PORT:?Missing DB_PORT}"
: "${DB_NAME:?Missing DB_NAME}"
: "${DB_USER:?Missing DB_USER}"
: "${DB_PASSWORD:?Missing DB_PASSWORD}"

# Optional WP vars
WP_URL="${WP_URL:-http://localhost:8000}"
WP_TITLE="${WP_TITLE:-My Local WP}"
WP_ADMIN_USER="${WP_ADMIN_USER:-admin}"
WP_ADMIN_PASSWORD="${WP_ADMIN_PASSWORD:-admin}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.com}"
WP_TABLE_PREFIX="${WP_TABLE_PREFIX:-wp_}"
WP_DEBUG="${WP_DEBUG:-true}"

chown -R www-data:www-data /var/www/html || true

if [ ! -f "/var/www/html/wp-config.php" ]; then
  echo "✨ First run: preparing WordPress files…"

  # If directory is empty (no core), fetch latest WP
  if [ ! -f "/var/www/html/wp-load.php" ]; then
    echo "↓ Downloading WordPress core…"
    rm -rf /var/www/html/* /var/www/html/.[!.]* || true
    wp core download --path=/var/www/html --allow-root
  fi

  # Create wp-config.php using env vars
  echo "⚙️ Generating wp-config.php…"
  wp config create \
    --path=/var/www/html \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASSWORD}" \
    --dbhost="${DB_HOST}:${DB_PORT}" \
    --dbprefix="${WP_TABLE_PREFIX}" \
    --skip-check \
    --allow-root

  # Set salts
  echo "🔐 Injecting auth salts…"
  wp config shuffle-salts --allow-root

  # Toggle debug flags
  if [ "${WP_DEBUG}" = "true" ] || [ "${WP_DEBUG}" = "1" ]; then
    wp config set WP_DEBUG true --raw --type=constant --allow-root
    wp config set WP_DEBUG_LOG true --raw --type=constant --allow-root
    wp config set WP_DEBUG_DISPLAY false --raw --type=constant --allow-root
  fi

  # Install site if not already installed
  if ! wp core is-installed --allow-root; then
    echo "🧭 Running wp core install…"
    wp core install \
      --url="${WP_URL}" \
      --title="${WP_TITLE}" \
      --admin_user="${WP_ADMIN_USER}" \
      --admin_password="${WP_ADMIN_PASSWORD}" \
      --admin_email="${WP_ADMIN_EMAIL}" \
      --skip-email \
      --allow-root
  fi

  # Friendly perms for dev
  chown -R www-data:www-data /var/www/html
  find /var/www/html -type d -exec chmod 755 {} \;
  find /var/www/html -type f -exec chmod 644 {} \;

  echo "✅ WordPress ready at ${WP_URL}"
else
  echo "♻️ Using existing WordPress volume."
fi

# Ensure Apache can write logs
mkdir -p /var/log/apache2 && chown -R www-data:www-data /var/log/apache2

# Start Apache (foreground)
exec "$@"
