#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
#  MariaDB first-run bootstrap: users, DB, and permissions
#  All values come from environment variables (.env)
# ─────────────────────────────────────────────────────────

: "${DB_ROOT_PASSWORD:?Missing DB_ROOT_PASSWORD}"
: "${DB_NAME:?Missing DB_NAME}"
: "${DB_USER:?Missing DB_USER}"
: "${DB_PASSWORD:?Missing DB_PASSWORD}"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Initialize datadir if empty (MariaDB 10.11+)
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "✨ Initializing MariaDB data directory…"
  mariadb-install-db \
    --user=mysql \
    --datadir=/var/lib/mysql \
    --skip-test-db \
    --auth-root-authentication-method=normal
fi

# Start temporary server (no networking)
echo "🚀 Starting MariaDB (bootstrap)…"
mariadbd --skip-networking --socket=/run/mysqld/mysqld.sock --user=mysql &
BOOT_PID=$!

# Wait for socket
for i in {1..60}; do
  if mariadb-admin --socket=/run/mysqld/mysqld.sock ping &>/dev/null; then
    break
  fi
  sleep 1
done

# Secure and create DB/user
echo "🔐 Securing root account and creating database/user…"
mariadb --protocol=socket --socket=/run/mysqld/mysqld.sock <<-SQL
  ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
  DELETE FROM mysql.user WHERE User='' OR (User='root' AND Host NOT IN ('localhost'));
  FLUSH PRIVILEGES;

  CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
  CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
  GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
  FLUSH PRIVILEGES;
SQL

# Stop bootstrap server
mariadb-admin --socket=/run/mysqld/mysqld.sock -uroot -p"${DB_ROOT_PASSWORD}" shutdown

echo "✅ MariaDB initialized."

# Exec real server (takes over PID 1 via tini)
exec "$@"
