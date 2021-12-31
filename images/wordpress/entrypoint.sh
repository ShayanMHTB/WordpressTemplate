#!/bin/bash
# WordPress Entrypoint Script
# Initializes WordPress installation and configures the environment

set -eo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[WordPress Init]${NC} $1"
}

error() {
    echo -e "${RED}[WordPress Error]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WordPress Warning]${NC} $1"
}

info() {
    echo -e "${BLUE}[WordPress Info]${NC} $1"
}

# Wait for database to be ready
wait_for_db() {
    log "Waiting for database connection..."
    
    for i in {1..30}; do
        if mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
            log "Database connection established"
            return 0
        fi
        info "Waiting for database... ($i/30)"
        sleep 2
    done
    
    error "Database connection failed after 30 attempts"
    return 1
}

# Download WordPress if not present
download_wordpress() {
    if [ ! -f "wp-config.php" ] && [ ! -f "wp-settings.php" ]; then
        log "WordPress not found. Downloading latest version..."
        wp core download --allow-root
        log "WordPress downloaded successfully"
    else
        log "WordPress installation detected"
    fi
}

# Create wp-config.php if it doesn't exist
configure_wordpress() {
    if [ ! -f "wp-config.php" ]; then
        log "Creating wp-config.php..."
        
        # Create wp-config.php with database settings
        wp config create \
            --dbname="$WORDPRESS_DB_NAME" \
            --dbuser="$WORDPRESS_DB_USER" \
            --dbpass="$WORDPRESS_DB_PASSWORD" \
            --dbhost="$WORDPRESS_DB_HOST" \
            --dbcharset="utf8mb4" \
            --dbcollate="utf8mb4_unicode_ci" \
            --allow-root
        
        # Add security keys if not present
        if [ -n "$WORDPRESS_AUTH_KEY" ]; then
            wp config set AUTH_KEY "$WORDPRESS_AUTH_KEY" --allow-root
        fi
        if [ -n "$WORDPRESS_SECURE_AUTH_KEY" ]; then
            wp config set SECURE_AUTH_KEY "$WORDPRESS_SECURE_AUTH_KEY" --allow-root
        fi
        if [ -n "$WORDPRESS_LOGGED_IN_KEY" ]; then
            wp config set LOGGED_IN_KEY "$WORDPRESS_LOGGED_IN_KEY" --allow-root
        fi
        if [ -n "$WORDPRESS_NONCE_KEY" ]; then
            wp config set NONCE_KEY "$WORDPRESS_NONCE_KEY" --allow-root
        fi
        if [ -n "$WORDPRESS_AUTH_SALT" ]; then
            wp config set AUTH_SALT "$WORDPRESS_AUTH_SALT" --allow-root
        fi
        if [ -n "$WORDPRESS_SECURE_AUTH_SALT" ]; then
            wp config set SECURE_AUTH_SALT "$WORDPRESS_SECURE_AUTH_SALT" --allow-root
        fi
        if [ -n "$WORDPRESS_LOGGED_IN_SALT" ]; then
            wp config set LOGGED_IN_SALT "$WORDPRESS_LOGGED_IN_SALT" --allow-root
        fi
        if [ -n "$WORDPRESS_NONCE_SALT" ]; then
            wp config set NONCE_SALT "$WORDPRESS_NONCE_SALT" --allow-root
        fi
        
        # Set debug settings
        wp config set WP_DEBUG "${WP_DEBUG:-false}" --raw --allow-root
        wp config set WP_DEBUG_LOG "${WP_DEBUG_LOG:-false}" --raw --allow-root
        wp config set WP_DEBUG_DISPLAY "${WP_DEBUG_DISPLAY:-false}" --raw --allow-root
        
        log "wp-config.php created successfully"
    else
        log "wp-config.php already exists"
    fi
}

# Install WordPress if not already installed
install_wordpress() {
    if ! wp core is-installed --allow-root 2>/dev/null; then
        log "Installing WordPress..."
        
        wp core install \
            --url="$WORDPRESS_URL" \
            --title="$WORDPRESS_TITLE" \
            --admin_user="$WORDPRESS_ADMIN_USER" \
            --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
            --admin_email="$WORDPRESS_ADMIN_EMAIL" \
            --allow-root
        
        log "WordPress installation completed successfully"
        log "Admin URL: $WORDPRESS_URL/wp-admin"
        log "Admin User: $WORDPRESS_ADMIN_USER"
    else
        log "WordPress is already installed"
    fi
}

# Set proper file permissions
set_permissions() {
    log "Setting file permissions..."
    
    # Set ownership to www-data
    find /var/www/html -type d -exec chmod 755 {} \;
    find /var/www/html -type f -exec chmod 644 {} \;
    
    # Make wp-config.php read-only for security
    if [ -f "wp-config.php" ]; then
        chmod 600 wp-config.php
    fi
    
    # Ensure uploads directory is writable
    mkdir -p wp-content/uploads
    chmod -R 755 wp-content/uploads
    
    log "File permissions set successfully"
}

# Main initialization function
initialize_wordpress() {
    log "Starting WordPress initialization..."
    
    # Download WordPress core files
    download_wordpress
    
    # Wait for database to be ready
    if ! wait_for_db; then
        error "Could not establish database connection. Exiting."
        exit 1
    fi
    
    # Configure WordPress
    configure_wordpress
    
    # Install WordPress if needed
    install_wordpress
    
    # Set proper permissions
    set_permissions
    
    log "WordPress initialization completed successfully"
}

    # Check if required environment variables are set
check_environment() {
    local required_vars=(
        "WORDPRESS_DB_NAME"
        "WORDPRESS_DB_USER" 
        "WORDPRESS_DB_PASSWORD"
        "WORDPRESS_DB_HOST"
        "WORDPRESS_URL"
        "WORDPRESS_TITLE"
        "WORDPRESS_ADMIN_USER"
        "WORDPRESS_ADMIN_PASSWORD"
        "WORDPRESS_ADMIN_EMAIL"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            error "  - $var"
        done
        exit 1
    fi
}

# Main execution
main() {
    log "WordPress container starting..."
    
    # Check environment variables
    check_environment
    
    # Initialize WordPress
    initialize_wordpress
    
    log "Starting PHP development server..."
    info "WordPress is ready at: $WORDPRESS_URL"
    
    # Execute PHP built-in server instead of PHP-FPM
    exec php -S 0.0.0.0:8000 -t /var/www/html
}

# Run main function
main "$@"
