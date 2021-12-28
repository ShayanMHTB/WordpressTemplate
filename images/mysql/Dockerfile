# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃  MariaDB on Debian — simple, secure, .env-driven   ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# ✨ Base tools + MariaDB server
RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-server mariadb-client ca-certificates tzdata curl tini \
  && rm -rf /var/lib/apt/lists/*

# 🕒 Timezone passed via env (TZ)
ENV TZ=UTC

# 🔧 Drop-in config (optional spot if you later add custom my.cnf)
# COPY my.cnf /etc/mysql/mariadb.conf.d/99-local.cnf

# 🏁 Custom entrypoint to init DB from .env
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3306

# 🚀 tini for sane PID 1, then our entrypoint
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["mariadbd", "--user=mysql", "--bind-address=0.0.0.0"]
