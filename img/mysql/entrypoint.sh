#!/bin/bash
set -e

# Set default values if not provided
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-root}
MYSQL_DATABASE=${MYSQL_DATABASE:-wordpress}
MYSQL_USER=${MYSQL_USER:-wordpress}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-wordpress}

echo "[Entrypoint] Starting MariaDB setup..."

# Ensure MySQL run dir exists
mkdir -p "$MYSQL_RUN_DIR"
chown -R mysql:mysql "$MYSQL_RUN_DIR"

# Initialize the database directory if empty
if [ ! -d "$MYSQL_DATA_DIR/mysql" ]; then
    echo "[Entrypoint] Initializing database..."
    mariadb-install-db --user=mysql --datadir="$MYSQL_DATA_DIR"
    echo "[Entrypoint] Database initialized."

    # Start the MariaDB server in the background
    mysqld_safe --datadir="$MYSQL_DATA_DIR" &
    sleep 5

    echo "[Entrypoint] Creating database and user..."

    mysql -uroot <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL

    echo "[Entrypoint] DB and user created. Shutting down temp MariaDB..."

    mysqladmin -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
fi

echo "[Entrypoint] Starting MariaDB server..."
exec mysqld --user=mysql --datadir="$MYSQL_DATA_DIR"
