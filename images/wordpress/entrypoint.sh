#!/bin/bash

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WordPress Container Entrypoint
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WordPress: $*"
}

# Wait for MySQL to be ready
wait_for_mysql() {
    log "Waiting for MySQL connection..."
    
    local count=0
    until mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
        count=$((count + 1))
        if [ $count -gt 30 ]; then
            log "MySQL connection timeout!"
            exit 1
        fi
        log "MySQL not ready, waiting... ($count/30)"
        sleep 2
    done
    
    log "MySQL connection established"
}

# Download and setup WordPress if not exists
setup_wordpress() {
    if [ ! -f index.php ]; then
        log "WordPress not found, downloading version: $WORDPRESS_VERSION"
        
        if [ "$WORDPRESS_VERSION" = "latest" ]; then
            wp core download --allow-root
        else
            wp core download --version="$WORDPRESS_VERSION" --allow-root
        fi
        
        log "WordPress downloaded successfully"
    fi
    
    # Create wp-config.php if it doesn't exist
    if [ ! -f wp-config.php ]; then
        log "Creating wp-config.php"
        
        wp config create \
            --dbname="$WORDPRESS_DB_NAME" \
            --dbuser="$WORDPRESS_DB_USER" \
            --dbpass="$WORDPRESS_DB_PASSWORD" \
            --dbhost="$WORDPRESS_DB_HOST" \
            --allow-root
        
        log "wp-config.php created"
    fi
}

main() {
    log "Starting WordPress container initialization"
    
    # Wait for database
    wait_for_mysql
    
    # Setup WordPress
    setup_wordpress
    
    log "WordPress initialization complete"
    log "Starting PHP-FPM"
    
    # Execute the main command
    exec "$@"
}

main "$@"
