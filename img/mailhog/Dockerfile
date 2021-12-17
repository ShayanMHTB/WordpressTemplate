ARG DEBIAN_VERSION=bookworm
FROM debian:${DEBIAN_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

# Install MailHog dependencies and download binary
RUN apt-get update && apt-get install -y wget ca-certificates && \
    wget -O /usr/local/bin/mailhog https://github.com/mailhog/MailHog/releases/download/v1.0.1/MailHog_linux_amd64 && \
    chmod +x /usr/local/bin/mailhog && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8025 1025

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
