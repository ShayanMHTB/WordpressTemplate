# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MySQL Custom Image - Alpine Base
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ARG MYSQL_VERSION=8.0

FROM alpine:3.19

# Install MySQL and dependencies
RUN apk add --no-cache \
    bash \
    mysql \
    mysql-client \
    openrc \
    && mkdir -p /var/lib/mysql \
    && mkdir -p /run/mysqld \
    && mkdir -p /var/log/mysql

# Create MySQL user and set permissions
RUN addgroup -g 999 mysql \
    && adduser -D -s /bin/bash -G mysql -u 999 mysql \
    && chown -R mysql:mysql /var/lib/mysql \
    && chown -R mysql:mysql /run/mysqld \
    && chown -R mysql:mysql /var/log/mysql

# Copy entrypoint script
COPY images/mysql/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create MySQL configuration directory
RUN mkdir -p /etc/mysql/mysql.conf.d

# Basic MySQL configuration
RUN echo '[mysqld]' > /etc/mysql/my.cnf \
    && echo 'user = mysql' >> /etc/mysql/my.cnf \
    && echo 'datadir = /var/lib/mysql' >> /etc/mysql/my.cnf \
    && echo 'socket = /run/mysqld/mysqld.sock' >> /etc/mysql/my.cnf \
    && echo 'pid-file = /run/mysqld/mysqld.pid' >> /etc/mysql/my.cnf \
    && echo 'bind-address = 0.0.0.0' >> /etc/mysql/my.cnf \
    && echo 'default-authentication-plugin = mysql_native_password' >> /etc/mysql/my.cnf \
    && echo 'character-set-server = utf8mb4' >> /etc/mysql/my.cnf \
    && echo 'collation-server = utf8mb4_unicode_ci' >> /etc/mysql/my.cnf

EXPOSE 3306

VOLUME ["/var/lib/mysql"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["mysqld"]
