# 🚀 WordPress Docker Dev Environment

> 🧱 A customizable, developer-friendly WordPress development template powered by Docker, built entirely from minimal Debian-based images.

---

![Docker](https://img.shields.io/badge/Docker-Engine-blue?logo=docker)
![WordPress](https://img.shields.io/badge/WordPress-6.x-blue?logo=wordpress)
![PHP](https://img.shields.io/badge/PHP-8.x-blue?logo=php)
![MariaDB](https://img.shields.io/badge/MariaDB/MySQL-Supported-blue?logo=mysql)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)

---

## ✨ Features

- 🐳 **Dockerized** environment (from scratch)
- ⚙️ Built on **Debian Bookworm**
- 🗂️ Isolated custom images for:
  - WordPress + WP-CLI
  - MySQL or MariaDB
  - phpMyAdmin
  - MailHog for email testing
- 💾 Database persistence to host
- 🔄 `.env`-based configuration
- 🧪 5-minute WordPress setup with `wp-cli`
- 📬 Instant mail debugging with MailHog UI
- 🔌 Easily extendable with new tools

---

## 🧠 Project Structure

```
📁 your-project/
├── .env              # Your actual environment variables
├── .env.example      # Template environment file
├── docker-compose.yml
├── web/              # WordPress root directory
├── dbs/              # Host-mirrored DB data
└── img/              # All custom images
    ├── wordpress/
    │   ├── Dockerfile
    │   └── entrypoint.sh
    ├── mysql/
    │   ├── Dockerfile
    │   └── entrypoint.sh
    ├── mariadb/
    │   ├── Dockerfile
    │   └── entrypoint.sh
    └── mailhog/
        ├── Dockerfile
        └── entrypoint.sh
```

---

## ⚙️ Requirements

- Docker 🐳
- Docker Compose
- Optional: [Make](https://www.gnu.org/software/make/) for command shortcuts

---

## 🚀 Getting Started

1. **Clone the repo**  
   ```bash
   git clone https://github.com/your-username/your-project.git
   cd your-project
   ```

2. **Copy the environment file**
   ```bash
   cp .env.example .env
   ```

3. **Set DB_ENGINE** in `.env`  
   Options: `mysql` or `mariadb`

4. **Start the environment**
   ```bash
   docker compose up --build
   ```

5. **Visit in your browser**:
   - 🌐 WordPress: [http://localhost:8000](http://localhost:8000)
   - 🧠 phpMyAdmin: [http://localhost:8080](http://localhost:8080)
   - 📬 MailHog: [http://localhost:8025](http://localhost:8025)

---

## 🔧 WP-CLI Examples

Run WP CLI commands directly inside the WordPress container:

```bash
docker compose exec web wp core version --allow-root
docker compose exec web wp plugin list --allow-root
docker compose exec web wp user list --allow-root
```

---

## 📬 Email with MailHog

MailHog captures any emails sent by WordPress.  
Use plugin like **WP Mail SMTP** or configure `wp-config.php` to point to:

- **SMTP Host**: `mailhog`
- **SMTP Port**: `1025`
- **No authentication or encryption needed**

---

## 🧩 Switching between MySQL and MariaDB

In `.env`:

```env
DB_ENGINE=mysql   # or mariadb
```

Then rebuild:

```bash
docker compose down
docker compose build dbs
docker compose up
```

---

## 🛠️ Extending

You can easily add:
- SSL support (mkcert or certbot)
- Redis for caching
- Nginx as a reverse proxy
- Xdebug for debugging
- Custom php.ini settings

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙌 Credits

- [WordPress](https://wordpress.org/)
- [WP-CLI](https://wp-cli.org/)
- [MailHog](https://github.com/mailhog/MailHog)
- [phpMyAdmin](https://www.phpmyadmin.net/)
- [Docker](https://www.docker.com/)
