# SETUP

## Prerequisites

Ensure your development machine has the following installed:

### Required Software

- **Docker Engine**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **Git**: Version 2.30 or higher
- **Text Editor/IDE**: VS Code, PhpStorm, or similar

### System Requirements

- **RAM**: Minimum 4GB, recommended 8GB+
- **Storage**: At least 2GB free space
- **OS**: Linux, macOS, or Windows 10/11 with WSL2

## Initial Setup

### 1. Repository Setup

```bash
# Clone the repository
git clone <your-repository-url> wordpress-template
cd wordpress-template

# Verify project structure
ls -la
```

### 2. Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env  # or your preferred editor
```

### Required Environment Variables

```bash
# Database Configuration
DB_NAME=wordpress_dev
DB_USER=wp_user
DB_PASSWORD=your_secure_password
DB_ROOT_PASSWORD=root_secure_password
DB_HOST=database

# WordPress Configuration
WP_URL=http://localhost:8080
WP_TITLE="WordPress Development Site"
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=admin_secure_password
WP_ADMIN_EMAIL=admin@example.local

# Security Keys (generate at https://api.wordpress.org/secret-key/1.1/salt/)
WP_AUTH_KEY=your_unique_phrase
WP_SECURE_AUTH_KEY=your_unique_phrase
WP_LOGGED_IN_KEY=your_unique_phrase
WP_NONCE_KEY=your_unique_phrase
WP_AUTH_SALT=your_unique_phrase
WP_SECURE_AUTH_SALT=your_unique_phrase
WP_LOGGED_IN_SALT=your_unique_phrase
WP_NONCE_SALT=your_unique_phrase

# Development Settings
WP_DEBUG=true
WP_DEBUG_LOG=true
WP_DEBUG_DISPLAY=false
```

### 3. Docker Setup

#### Build and Start Services

```bash
# Build custom Docker images
docker-compose build

# Start all services
docker-compose up -d

# Check service status
docker-compose ps
```

#### Verify Installation

```bash
# Check WordPress container logs
docker-compose logs wordpress

# Check database container
docker-compose logs database

# Access WordPress container shell
docker-compose exec wordpress bash
```

## Service Configuration

### WordPress Service

- **Port**: 8080 (configurable via docker-compose.yml)
- **Document Root**: `/var/www/html`
- **PHP Version**: 8.0+
- **Extensions**: All WordPress-required extensions enabled

### Database Service

- **Port**: 3306 (not exposed by default)
- **Storage**: Persistent in `./database` directory
- **Charset**: utf8mb4
- **Collation**: utf8mb4_unicode_ci

### Additional Services

- **Redis Cache**: Port 6379 (internal)
- **MailHog**: Port 8025 (web interface)
- **Adminer**: Port 8081 (database management)

## First-Time WordPress Setup

### 1. Access WordPress

Navigate to http://localhost:8080 in your browser.

### 2. Complete WordPress Installation

The installation should be automated based on your `.env` configuration. If manual setup is required:

1. Select language
2. Enter database details (from your .env file)
3. Create admin user (use credentials from .env)
4. Install WordPress

### 3. Verify Installation

```bash
# Check WordPress files
docker-compose exec wordpress ls -la /var/www/html

# Verify database connection
docker-compose exec wordpress wp db check --allow-root

# Check WordPress status
docker-compose exec wordpress wp core version --allow-root
```

## Development Environment Setup

### Install WP-CLI

WP-CLI is included in the Docker container:

```bash
# Access container
docker-compose exec wordpress bash

# Use WP-CLI commands
wp --info
wp plugin list
wp theme list
```

### Enable Debug Mode

Debug settings are configured via environment variables. To view debug logs:

```bash
# Follow WordPress debug log
docker-compose exec wordpress tail -f /var/www/html/wp-content/debug.log
```

### Database Management

Access database via Adminer:

- URL: http://localhost:8081
- Server: database
- Username: wp_user (or root)
- Password: (from your .env file)
- Database: wordpress_dev

## Common Setup Issues

### Port Conflicts

If default ports are in use:

```bash
# Edit docker-compose.yml to change port mappings
# For example, change "8080:80" to "8081:80"
```

### Permission Issues

```bash
# Fix file permissions
docker-compose exec wordpress chown -R www-data:www-data /var/www/html
docker-compose exec wordpress chmod -R 755 /var/www/html
```

### Database Connection Issues

```bash
# Reset database
docker-compose down -v
docker-compose up --build
```

### Memory Issues

Increase Docker resource allocation in Docker Desktop settings or adjust PHP memory limits in the Dockerfile.

## Next Steps

After successful setup:

1. Review [DEVELOPMENT.md](DEVELOPMENT.md) for workflow guidelines
2. Check [SECURITY.md](SECURITY.md) for security configurations
3. Explore [ARCHITECTURE.md](ARCHITECTURE.md) for system understanding

## Backup and Restore

### Create Backup

```bash
# Database backup
docker-compose exec database mysqldump -u root -p wordpress_dev > backup.sql

# Files backup
docker-compose exec wordpress tar -czf backup.tar.gz /var/www/html/wp-content
```

### Restore from Backup

```bash
# Database restore
docker-compose exec -T database mysql -u root -p wordpress_dev < backup.sql

# Files restore
docker-compose exec wordpress tar -xzf backup.tar.gz -C /var/www/html/
```
