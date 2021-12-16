# Use an ARG to optionally override Debian version
ARG DEBIAN_VERSION=bookworm
FROM debian:${DEBIAN_VERSION}

# Set environment variables
ENV MYSQL_USER=mysql \
    MYSQL_DATA_DIR=/var/lib/mysql \
    MYSQL_RUN_DIR=/run/mysqld \
    MYSQL_LOG_DIR=/var/log/mysql \
    DEBIAN_FRONTEND=noninteractive

# Install necessary packages and MariaDB server
RUN apt-get update && apt-get install -y \
    gnupg \
    lsb-release \
    wget \
    curl \
    ca-certificates \
    mariadb-server \
    mariadb-client \
    procps \
    pwgen \
    iputils-ping \
    vim \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p ${MYSQL_RUN_DIR} ${MYSQL_LOG_DIR} ${MYSQL_DATA_DIR} \
    && chown -R mysql:mysql ${MYSQL_RUN_DIR} ${MYSQL_LOG_DIR} ${MYSQL_DATA_DIR}

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set volume for persistent data
VOLUME ["${MYSQL_DATA_DIR}"]

# Expose MariaDB default port
EXPOSE 3306

# Use custom entrypoint
ENTRYPOINT ["entrypoint.sh"]
