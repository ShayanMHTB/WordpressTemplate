#!/bin/bash

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MySQL Container Entrypoint
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] MySQL: $*"
}

# Initialize MySQL data directory if empty
initialize_database() {
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        log "Initializing MySQL database"
        
        # Install MySQL system tables
        mysql_install_db --user=mysql --datadir=/var/lib/mysql --rpm
        
        log "MySQL database initialized"
    fi
}

# Start MySQL temporarily for setup
start_temp_mysql() {
    log "Starting temporary MySQL server"
    mysqld --user=mysql --skip-networking --socket=/tmp/mysql_temp.sock &
    local temp_pid=$!
    
    # Wait for MySQL to start
    local count=0
    until mysql --socket=/tmp/mysql_temp.sock -e "SELECT 1" >/dev/null 2>&1; do
        count=$((count + 1))
        if [ $count -gt 30 ]; then
            log "Temporary MySQL startup timeout!"
            exit 1
        fi
        sleep 1
    done
    
    log "Temporary MySQL server started"
    echo $temp_pid
}

# Setup MySQL users and databases
setup_mysql() {
    local temp_pid=$1
    
    log "Setting up MySQL users and databases"
    
    # Set root password
    if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
        mysql --socket=/tmp/mysql_temp.sock -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
        mysql --socket=/tmp/mysql_temp.sock -e "CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
        mysql --socket=/tmp/mysql_temp.sock -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;"
        log "Root password set"
    fi
    
    # Create application database and user
    if [ -n "$MYSQL_DATABASE" ]; then
        mysql --socket=/tmp/mysql_temp.sock -e "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        log "Database '$MYSQL_DATABASE' created"
    fi
    
    if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_PASSWORD" ]; then
        mysql --socket=/tmp/mysql_temp.sock -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
        
        if [ -n "$MYSQL_DATABASE" ]; then
            mysql --socket=/tmp/mysql_temp.sock -e "GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';"
        fi
        
        log "User '$MYSQL_USER' created"
    fi
    
    mysql --socket=/tmp/mysql_temp.sock -e "FLUSH PRIVILEGES;"
    
    # Stop temporary MySQL
    log "Stopping temporary MySQL server"
    kill $temp_pid
    wait $temp_pid 2>/dev/null || true
}

main() {
    log "Starting MySQL container initialization"
    
    # Initialize database if needed
    initialize_database
    
    # Check if this is the first run
    if [ ! -f "/var/lib/mysql/.mysql_configured" ]; then
        # Start temporary MySQL for configuration
        temp_pid=$(start_temp_mysql)
        
        # Setup users and databases
        setup_mysql $temp_pid
        
        # Mark as configured
        touch /var/lib/mysql/.mysql_configured
        
        log "MySQL configuration complete"
    else
        log "MySQL already configured, skipping setup"
    fi
    
    log "Starting MySQL server"
    
    # Execute the main command
    exec "$@" --user=mysql
}

main "$@"
