#!/bin/bash
# MySQL Entrypoint Script
# Initializes MySQL database with security settings and user setup

set -eo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[MySQL Init]${NC} $1"
}

error() {
    echo -e "${RED}[MySQL Error]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[MySQL Warning]${NC} $1"
}

# Check if data directory is empty (first run)
if [ ! -d "/var/lib/mysql/mysql" ]; then
    log "Initializing MySQL data directory..."
    
    # Initialize MySQL data directory
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    log "Starting temporary MySQL server for setup..."
    
    # Start MySQL in background for initial setup
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/tmp/mysql_init.sock &
    MYSQL_PID=$!
    
    # Wait for MySQL to be ready
    for i in {1..30}; do
        if mysqladmin --socket=/tmp/mysql_init.sock ping >/dev/null 2>&1; then
            break
        fi
        log "Waiting for MySQL to start... ($i/30)"
        sleep 1
    done
    
    if ! mysqladmin --socket=/tmp/mysql_init.sock ping >/dev/null 2>&1; then
        error "MySQL failed to start within 30 seconds"
        exit 1
    fi
    
    log "MySQL is ready for configuration"
    
    # Set root password if provided
    if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
        log "Setting root password..."
        mysql --socket=/tmp/mysql_init.sock -u root <<-EOSQL
            ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
            CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
            GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
            DELETE FROM mysql.user WHERE User='';
            DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1', '%');
            DROP DATABASE IF EXISTS test;
            DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
            FLUSH PRIVILEGES;
EOSQL
    else
        warn "No root password set (MYSQL_ROOT_PASSWORD not provided)"
    fi
    
    # Create database if specified
    if [ -n "$MYSQL_DATABASE" ]; then
        log "Creating database: $MYSQL_DATABASE"
        mysql --socket=/tmp/mysql_init.sock -u root -p"$MYSQL_ROOT_PASSWORD" <<-EOSQL
            CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOSQL
    fi
    
    # Create user if specified
    if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_PASSWORD" ]; then
        log "Creating user: $MYSQL_USER"
        mysql --socket=/tmp/mysql_init.sock -u root -p"$MYSQL_ROOT_PASSWORD" <<-EOSQL
            CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
EOSQL
        
        # Grant privileges to database if both user and database are specified
        if [ -n "$MYSQL_DATABASE" ]; then
            log "Granting privileges to $MYSQL_USER on $MYSQL_DATABASE"
            mysql --socket=/tmp/mysql_init.sock -u root -p"$MYSQL_ROOT_PASSWORD" <<-EOSQL
                GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
                FLUSH PRIVILEGES;
EOSQL
        fi
    fi
    
    # Stop the temporary server
    log "Stopping temporary MySQL server..."
    kill $MYSQL_PID
    wait $MYSQL_PID
    
    log "MySQL initialization completed successfully"
else
    log "MySQL data directory already exists, skipping initialization"
fi

# Start MySQL in foreground
log "Starting MySQL server..."
exec "$@" --bind-address=0.0.0.0
