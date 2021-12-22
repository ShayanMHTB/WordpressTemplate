# DEPLOYMENT

## Deployment Strategy

This WordPress template supports multiple deployment strategies, from simple staging environments to complex production infrastructures. Each deployment type has specific configurations and considerations.

## Environment Types

### Development Environment

- **Purpose**: Local development and testing
- **Configuration**: Full debug mode, development plugins
- **Database**: Local MySQL with sample data
- **Performance**: Optimized for development speed
- **Security**: Relaxed for productivity

### Staging Environment

- **Purpose**: Pre-production testing and client review
- **Configuration**: Production-like settings with debug logging
- **Database**: Copy of production data (sanitized)
- **Performance**: Production-equivalent performance testing
- **Security**: Production-level security with additional monitoring

### Production Environment

- **Purpose**: Live website serving real users
- **Configuration**: Optimized for performance and security
- **Database**: Primary database with full backups
- **Performance**: Maximum optimization, caching enabled
- **Security**: Full security hardening and monitoring

## Docker Deployment Configurations

### Development (docker-compose.yml)

```yaml
version: '3.8'
services:
  wordpress:
    build: .
    environment:
      - WP_DEBUG=true
      - WP_DEBUG_LOG=true
      - WP_DEBUG_DISPLAY=true
    ports:
      - '8080:80'
    volumes:
      - ./wp-content:/var/www/html/wp-content
```

### Staging (docker-compose.staging.yml)

```yaml
version: '3.8'
services:
  wordpress:
    build:
      context: .
      target: production
    environment:
      - WP_DEBUG=true
      - WP_DEBUG_LOG=true
      - WP_DEBUG_DISPLAY=false
    restart: unless-stopped
    networks:
      - staging_network

  database:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      - MYSQL_DATABASE=${DB_NAME}
      - MYSQL_USER=${DB_USER}
      - MYSQL_PASSWORD=${DB_PASSWORD}
    volumes:
      - staging_db:/var/lib/mysql
    restart: unless-stopped
    networks:
      - staging_network

networks:
  staging_network:
    driver: bridge

volumes:
  staging_db:
```

### Production (docker-compose.production.yml)

```yaml
version: '3.8'
services:
  wordpress:
    build:
      context: .
      target: production
    environment:
      - WP_DEBUG=false
      - WP_DEBUG_LOG=true
      - WP_DEBUG_DISPLAY=false
    restart: always
    deploy:
      replicas: 2
      resources:
        limits:
          memory: 512M
          cpus: '1.0'
    networks:
      - production_network
      - traefik_network
    labels:
      - 'traefik.enable=true'
      - 'traefik.http.routers.wordpress.rule=Host(`yourdomain.com`)'
      - 'traefik.http.routers.wordpress.tls.certresolver=letsencrypt'

  database:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      - MYSQL_DATABASE=${DB_NAME}
      - MYSQL_USER=${DB_USER}
      - MYSQL_PASSWORD=${DB_PASSWORD}
    volumes:
      - production_db:/var/lib/mysql
      - ./database/backups:/backups
    restart: always
    networks:
      - production_network

  redis:
    image: redis:7-alpine
    restart: always
    networks:
      - production_network
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

  traefik:
    image: traefik:v2.9
    command:
      - '--api.dashboard=true'
      - '--providers.docker=true'
      - '--entrypoints.web.address=:80'
      - '--entrypoints.websecure.address=:443'
      - '--certificatesresolvers.letsencrypt.acme.tlschallenge=true'
      - '--certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL}'
      - '--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json'
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - '/var/run/docker.sock:/var/run/docker.sock:ro'
      - './letsencrypt:/letsencrypt'
    networks:
      - traefik_network

networks:
  production_network:
    driver: bridge
  traefik_network:
    external: true

volumes:
  production_db:
  redis_data:
```

## Deployment Processes

### Manual Deployment

#### Staging Deployment

```bash
# 1. Build and test locally first
docker-compose build
docker-compose up -d
# Run tests and validation

# 2. Deploy to staging
scp -r . user@staging-server:/var/www/wordpress-template/
ssh user@staging-server "cd /var/www/wordpress-template && docker-compose -f docker-compose.staging.yml up -d --build"

# 3. Verify deployment
curl -I https://staging.yourdomain.com
docker-compose -f docker-compose.staging.yml logs wordpress
```

#### Production Deployment

```bash
# 1. Backup current production
ssh user@production-server "cd /var/www/wordpress-template && ./scripts/backup.sh"

# 2. Deploy new version
rsync -avz --exclude-from='.deployignore' . user@production-server:/var/www/wordpress-template/
ssh user@production-server "cd /var/www/wordpress-template && docker-compose -f docker-compose.production.yml up -d --build"

# 3. Verify and monitor
./scripts/health-check.sh
./scripts/monitor-deployment.sh
```

### Automated CI/CD Pipeline

#### GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy WordPress Template

on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.1'
          tools: composer, phpcs

      - name: Install dependencies
        run: composer install

      - name: Run tests
        run: |
          phpcs --standard=WordPress-Extra wp-content/
          phpunit tests/

      - name: Build assets
        run: |
          npm install
          npm run build

  deploy-staging:
    if: github.ref == 'refs/heads/staging'
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to staging
        run: |
          ssh ${{ secrets.STAGING_USER }}@${{ secrets.STAGING_HOST }} "
            cd /var/www/wordpress-template &&
            git pull origin staging &&
            docker-compose -f docker-compose.staging.yml up -d --build
          "

  deploy-production:
    if: github.ref == 'refs/heads/main'
    needs: test
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Create backup
        run: |
          ssh ${{ secrets.PROD_USER }}@${{ secrets.PROD_HOST }} "
            cd /var/www/wordpress-template && ./scripts/backup.sh
          "

      - name: Deploy to production
        run: |
          ssh ${{ secrets.PROD_USER }}@${{ secrets.PROD_HOST }} "
            cd /var/www/wordpress-template &&
            git pull origin main &&
            docker-compose -f docker-compose.production.yml up -d --build
          "

      - name: Verify deployment
        run: |
          curl -f https://yourdomain.com/wp-admin/admin-ajax.php?action=heartbeat
```

#### GitLab CI/CD Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  DOCKER_DRIVER: overlay2

test:
  stage: test
  image: php:8.1
  before_script:
    - apt-get update && apt-get install -y git unzip
    - curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
  script:
    - composer install
    - phpcs --standard=WordPress-Extra wp-content/
    - phpunit tests/

build:
  stage: build
  image: node:16
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour

deploy_staging:
  stage: deploy
  only:
    - staging
  script:
    - rsync -avz . ${STAGING_USER}@${STAGING_HOST}:/var/www/wordpress-template/
    - ssh ${STAGING_USER}@${STAGING_HOST} "cd /var/www/wordpress-template && docker-compose -f docker-compose.staging.yml up -d --build"

deploy_production:
  stage: deploy
  only:
    - main
  when: manual
  script:
    - ssh ${PROD_USER}@${PROD_HOST} "cd /var/www/wordpress-template && ./scripts/backup.sh"
    - rsync -avz . ${PROD_USER}@${PROD_HOST}:/var/www/wordpress-template/
    - ssh ${PROD_USER}@${PROD_HOST} "cd /var/www/wordpress-template && docker-compose -f docker-compose.production.yml up -d --build"
```

## Server Configuration

### Minimum Server Requirements

#### Staging Server

- **CPU**: 2 cores
- **RAM**: 4GB
- **Storage**: 50GB SSD
- **OS**: Ubuntu 20.04 LTS or CentOS 8
- **Docker**: Latest stable version
- **Network**: 1Gbps connection

#### Production Server

- **CPU**: 4 cores (8 recommended)
- **RAM**: 8GB (16GB recommended)
- **Storage**: 100GB SSD (NVMe preferred)
- **OS**: Ubuntu 20.04 LTS or CentOS 8
- **Docker**: Latest stable version
- **Network**: 10Gbps connection
- **SSL**: Let's Encrypt or commercial certificate

### Server Setup Scripts

#### Initial Server Setup

```bash
#!/bin/bash
# scripts/server-setup.sh

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install additional tools
sudo apt install -y htop nginx certbot python3-certbot-nginx fail2ban ufw

# Configure firewall
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# Configure fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

echo "Server setup complete!"
```

#### SSL Setup

```bash
#!/bin/bash
# scripts/ssl-setup.sh

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

# Install certbot
sudo apt install -y certbot python3-certbot-nginx

# Generate SSL certificate
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# Setup auto-renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -

echo "SSL setup complete for $DOMAIN"
```

## Database Deployment

### Database Migration Strategy

```bash
#!/bin/bash
# scripts/migrate-database.sh

SOURCE_ENV=$1
TARGET_ENV=$2

if [ -z "$SOURCE_ENV" ] || [ -z "$TARGET_ENV" ]; then
    echo "Usage: $0 <source_env> <target_env>"
    echo "Example: $0 staging production"
    exit 1
fi

# Backup target database
echo "Creating backup of $TARGET_ENV database..."
docker-compose -f docker-compose.$TARGET_ENV.yml exec database mysqldump -u root -p$DB_ROOT_PASSWORD $DB_NAME > backup-$TARGET_ENV-$(date +%Y%m%d-%H%M%S).sql

# Export source database
echo "Exporting $SOURCE_ENV database..."
docker-compose -f docker-compose.$SOURCE_ENV.yml exec database mysqldump -u root -p$DB_ROOT_PASSWORD $DB_NAME > migration-dump.sql

# Import to target
echo "Importing to $TARGET_ENV database..."
docker-compose -f docker-compose.$TARGET_ENV.yml exec -T database mysql -u root -p$DB_ROOT_PASSWORD $DB_NAME < migration-dump.sql

# URL replacement if needed
if [ "$TARGET_ENV" = "production" ]; then
    docker-compose -f docker-compose.production.yml exec wordpress wp search-replace 'staging.yourdomain.com' 'yourdomain.com' --allow-root
fi

echo "Database migration complete!"
```

### Backup Strategy

```bash
#!/bin/bash
# scripts/backup.sh

ENVIRONMENT=${1:-production}
BACKUP_DIR="/backups/$(date +%Y/%m/%d)"
RETENTION_DAYS=30

# Create backup directory
mkdir -p $BACKUP_DIR

# Database backup
echo "Backing up database..."
docker-compose -f docker-compose.$ENVIRONMENT.yml exec database mysqldump -u root -p$DB_ROOT_PASSWORD $DB_NAME | gzip > $BACKUP_DIR/database-$(date +%H%M%S).sql.gz

# Files backup
echo "Backing up files..."
tar -czf $BACKUP_DIR/wp-content-$(date +%H%M%S).tar.gz wp-content/

# Upload backup to cloud storage (optional)
if command -v aws &> /dev/null; then
    aws s3 sync /backups s3://your-backup-bucket/wordpress-backups/
fi

# Clean old backups
find /backups -type f -mtime +$RETENTION_DAYS -delete

echo "Backup completed: $BACKUP_DIR"
```

## Monitoring and Health Checks

### Health Check Script

```bash
#!/bin/bash
# scripts/health-check.sh

ENVIRONMENT=${1:-production}
DOMAIN=${2:-yourdomain.com}

echo "Running health checks for $ENVIRONMENT environment..."

# Check container status
echo "Checking container status..."
docker-compose -f docker-compose.$ENVIRONMENT.yml ps

# Check WordPress availability
echo "Checking WordPress availability..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)
if [ $HTTP_STATUS -eq 200 ]; then
    echo "✓ WordPress is responding"
else
    echo "✗ WordPress returned HTTP $HTTP_STATUS"
    exit 1
fi

# Check database connection
echo "Checking database connection..."
docker-compose -f docker-compose.$ENVIRONMENT.yml exec wordpress wp db check --allow-root
if [ $? -eq 0 ]; then
    echo "✓ Database connection is healthy"
else
    echo "✗ Database connection failed"
    exit 1
fi

# Check disk space
echo "Checking disk space..."
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
if [ $DISK_USAGE -lt 90 ]; then
    echo "✓ Disk usage: $DISK_USAGE%"
else
    echo "⚠ High disk usage: $DISK_USAGE%"
fi

# Check memory usage
echo "Checking memory usage..."
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.2f", $3*100/$2 }')
echo "Memory usage: $MEMORY_USAGE%"

echo "Health check completed!"
```

### Performance Monitoring

```bash
#!/bin/bash
# scripts/performance-monitor.sh

DOMAIN=${1:-yourdomain.com}
LOG_FILE="/var/log/performance-monitor.log"

# Function to log with timestamp
log_with_timestamp() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Monitor response time
RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' https://$DOMAIN)
log_with_timestamp "Response time: ${RESPONSE_TIME}s"

# Monitor database performance
DB_SLOW_QUERIES=$(docker-compose exec database mysql -u root -p$DB_ROOT_PASSWORD -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';" | tail -n 1 | awk '{print $2}')
log_with_timestamp "Slow queries: $DB_SLOW_QUERIES"

# Monitor container resource usage
CONTAINER_STATS=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep wordpress)
log_with_timestamp "Container stats: $CONTAINER_STATS"

# Send alerts if thresholds exceeded
if (( $(echo "$RESPONSE_TIME > 2.0" | bc -l) )); then
    echo "ALERT: High response time: ${RESPONSE_TIME}s" | mail -s "Performance Alert" admin@yourdomain.com
fi
```

## Rollback Procedures

### Automated Rollback

```bash
#!/bin/bash
# scripts/rollback.sh

ENVIRONMENT=${1:-production}
BACKUP_DATE=${2:-latest}

echo "Starting rollback for $ENVIRONMENT environment..."

# Stop current containers
docker-compose -f docker-compose.$ENVIRONMENT.yml down

# Restore from backup
if [ "$BACKUP_DATE" = "latest" ]; then
    BACKUP_FILE=$(ls -t /backups/database-*.sql.gz | head -n 1)
    CONTENT_FILE=$(ls -t /backups/wp-content-*.tar.gz | head -n 1)
else
    BACKUP_FILE="/backups/$BACKUP_DATE/database-*.sql.gz"
    CONTENT_FILE="/backups/$BACKUP_DATE/wp-content-*.tar.gz"
fi

# Restore database
echo "Restoring database from $BACKUP_FILE..."
gunzip -c $BACKUP_FILE | docker-compose -f docker-compose.$ENVIRONMENT.yml exec -T database mysql -u root -p$DB_ROOT_PASSWORD $DB_NAME

# Restore files
echo "Restoring files from $CONTENT_FILE..."
tar -xzf $CONTENT_FILE

# Restart containers
docker-compose -f docker-compose.$ENVIRONMENT.yml up -d

# Verify rollback
./scripts/health-check.sh $ENVIRONMENT

echo "Rollback completed!"
```

## Security Considerations

### Production Security Checklist

- [ ] SSL certificates installed and configured
- [ ] Firewall configured (UFW or iptables)
- [ ] SSH key-based authentication only
- [ ] Fail2ban configured for brute force protection
- [ ] Docker daemon secured
- [ ] Regular security updates scheduled
- [ ] Backup encryption enabled
- [ ] Monitoring and alerting configured
- [ ] Access logs reviewed regularly
- [ ] Intrusion detection system active

### Environment Isolation

- **Network isolation**: Separate Docker networks for each environment
- **Credential isolation**: Environment-specific secrets and keys
- **Data isolation**: Separate databases and file storage
- **Access control**: Role-based access for different environments

This deployment guide provides a comprehensive foundation for deploying WordPress applications across multiple environments while maintaining security, performance, and reliability standards.
