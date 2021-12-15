ARG DEBIAN_VERSION=bookworm
FROM debian:${DEBIAN_VERSION}

ENV MYSQL_USER=mysql \
    MYSQL_DATA_DIR=/var/lib/mysql \
    MYSQL_RUN_DIR=/run/mysqld \
    MYSQL_LOG_DIR=/var/log/mysql \
    DEBIAN_FRONTEND=noninteractive

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

RUN mkdir -p ${MYSQL_RUN_DIR} ${MYSQL_LOG_DIR} ${MYSQL_DATA_DIR} \
    && chown -R mysql:mysql ${MYSQL_RUN_DIR} ${MYSQL_LOG_DIR} ${MYSQL_DATA_DIR}

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["${MYSQL_DATA_DIR}"]

EXPOSE 3306

ENTRYPOINT ["entrypoint.sh"]
