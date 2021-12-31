# MySQL Docker Image
# Builds MySQL 8.0 on Debian base using alternative approach

FROM debian:bookworm-slim

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_ROOT_PASSWORD=""
ENV MYSQL_DATABASE=""
ENV MYSQL_USER=""
ENV MYSQL_PASSWORD=""

# Install MySQL 8.0 from Debian repositories
RUN apt-get update && apt-get install -y \
    # Core system packages
    ca-certificates \
    curl \
    gnupg2 \
    lsb-release \
    wget \
    # MySQL from Debian repos (using default MySQL packages)
    default-mysql-server \
    default-mysql-client \
    # Additional tools
    gosu \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create mysql user and set up directories (if not already exists)
RUN if ! getent group mysql > /dev/null 2>&1; then groupadd -r mysql; fi \
    && if ! getent passwd mysql > /dev/null 2>&1; then useradd -r -g mysql mysql; fi \
    && mkdir -p /var/lib/mysql /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
    && chmod 777 /var/run/mysqld

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose MySQL port
EXPOSE 3306

# Set working directory
WORKDIR /var/lib/mysql

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["mysqld", "--user=mysql"]
