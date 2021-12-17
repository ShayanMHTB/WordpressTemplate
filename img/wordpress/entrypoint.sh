#!/bin/bash
set -e

echo "[Entrypoint] Starting WordPress container..."

# Check if WordPress is already installed in the web root
if [ -z "$(ls -A /var/www/html)" ]; then
    echo "[Entrypoint] No WordPress files found. Downloading..."
    wp core download --allow-root
    echo "[Entrypoint] WordPress downloaded."
else
    echo "[Entrypoint] WordPress already exists. Skipping download."
fi

# Fix permissions (esp. when bind-mounting to host)
chown -R www-data:www-data /var/www/html

# Start Apache in foreground
exec apachectl -D FOREGROUND
