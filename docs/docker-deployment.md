# Docker Deployment Guide

This guide covers deploying Dev-PyNode using Docker and Docker Compose.

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- At least 4GB RAM
- At least 10GB disk space

## Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/Bionic-AI-Solutions/dev-pynode.git
cd dev-pynode
cp .env.example .env
```

### 2. Start Services

```bash
docker-compose up -d
```

### 3. Verify Deployment

```bash
# Check service status
docker-compose ps

# Check logs
docker-compose logs -f

# Test health endpoint
curl http://localhost:3000/health
```

## Service Architecture

### Core Services

| Service | Port | Description |
|---------|------|-------------|
| backend | 3000 | Node.js API server |
| frontend | 3001 | React frontend |
| postgres | 5432 | PostgreSQL database |
| redis | 6379 | Redis cache |
| minio | 9000 | S3-compatible storage |
| ollama | 11434 | Local AI server |

### Development Tools

| Service | Port | Description |
|---------|------|-------------|
| pgadmin | 5050 | Database management |
| redis-commander | 8081 | Redis management |
| grafana | 3001 | Monitoring dashboard |
| prometheus | 9090 | Metrics collection |

## Configuration

### Environment Variables

Key environment variables for Docker deployment:

```bash
# Application
NODE_ENV=production
APP_PORT=3000
APP_HOST=0.0.0.0

# Database
DB_HOST=postgres
DB_PORT=5432
DB_NAME=dev_template_db
DB_USER=postgres
DB_PASSWORD=your-secure-password

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password

# MinIO
MINIO_ENDPOINT=minio
MINIO_PORT=9000
MINIO_ACCESS_KEY=your-access-key
MINIO_SECRET_KEY=your-secret-key

# AI Services
OPENAI_API_KEY=your-openai-key
OLLAMA_BASE_URL=http://ollama:11434
```

### Docker Compose Configuration

The `docker-compose.yml` file defines all services:

```yaml
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    env_file:
      - .env
    depends_on:
      - postgres
      - redis
      - minio
    networks:
      - dev-pynode-network
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=dev_template_db
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - dev-pynode-network
    restart: unless-stopped
```

## Production Deployment

### 1. Production Configuration

Create a production environment file:

```bash
cp .env.example .env.production
```

Update production settings:

```bash
# .env.production
NODE_ENV=production
DEBUG=false
LOG_LEVEL=info

# Use strong passwords
DB_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)

# Production URLs
CORS_ORIGIN=https://yourdomain.com
```

### 2. Build Production Images

```bash
# Build all images
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

# Or build specific service
docker-compose build backend
```

### 3. Deploy Production Stack

```bash
# Start production services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Check deployment
docker-compose ps
```

### 4. Production Docker Compose Override

Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  backend:
    restart: always
    environment:
      - NODE_ENV=production
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
        reservations:
          memory: 1G
          cpus: '0.5'

  postgres:
    restart: always
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'

  redis:
    restart: always
    command: redis-server --requirepass ${REDIS_PASSWORD}
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.25'
```

## Scaling

### Horizontal Scaling

Scale individual services:

```bash
# Scale backend to 3 instances
docker-compose up -d --scale backend=3

# Scale with load balancer
docker-compose -f docker-compose.yml -f docker-compose.scale.yml up -d
```

Create `docker-compose.scale.yml`:

```yaml
version: '3.8'

services:
  backend:
    deploy:
      replicas: 3

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - backend
```

### Load Balancer Configuration

Create `nginx.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend_1:3000;
        server backend_2:3000;
        server backend_3:3000;
    }

    server {
        listen 80;
        
        location / {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

## Monitoring

### Health Checks

All services include health checks:

```yaml
services:
  backend:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Logging

Configure centralized logging:

```yaml
services:
  backend:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # Centralized logging with ELK stack
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.8.0
    environment:
      - discovery.type=single-node
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:8.8.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf

  kibana:
    image: docker.elastic.co/kibana/kibana:8.8.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
```

### Metrics Collection

Prometheus and Grafana are included:

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    volumes:
      - grafana_data:/var/lib/grafana
```

## Security

### Network Security

```yaml
networks:
  dev-pynode-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

  # Isolated network for sensitive services
  database-network:
    driver: bridge
    internal: true
```

### Secrets Management

Use Docker secrets for sensitive data:

```yaml
services:
  backend:
    secrets:
      - db_password
      - jwt_secret
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password
      - JWT_SECRET_FILE=/run/secrets/jwt_secret

secrets:
  db_password:
    file: ./secrets/db_password.txt
  jwt_secret:
    file: ./secrets/jwt_secret.txt
```

### SSL/TLS

Configure SSL with Let's Encrypt:

```yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
      - certbot_data:/var/www/certbot

  certbot:
    image: certbot/certbot
    volumes:
      - certbot_data:/var/www/certbot
    command: certonly --webroot --webroot-path=/var/www/certbot --email your-email@example.com --agree-tos --no-eff-email -d yourdomain.com
```

## Backup and Recovery

### Database Backup

```bash
# Create backup
docker-compose exec postgres pg_dump -U postgres dev_template_db > backup.sql

# Restore backup
docker-compose exec -T postgres psql -U postgres dev_template_db < backup.sql
```

### Automated Backups

Create backup script:

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Database backup
docker-compose exec -T postgres pg_dump -U postgres dev_template_db | gzip > "$BACKUP_DIR/db_$DATE.sql.gz"

# MinIO backup
docker-compose exec minio mc mirror /data "$BACKUP_DIR/minio_$DATE/"

# Cleanup old backups (keep 7 days)
find "$BACKUP_DIR" -name "*.gz" -mtime +7 -delete
```

Schedule with cron:

```bash
# Add to crontab
0 2 * * * /path/to/backup.sh
```

## Troubleshooting

### Common Issues

1. **Services not starting**
   ```bash
   # Check logs
   docker-compose logs backend
   
   # Check resource usage
   docker stats
   
   # Restart services
   docker-compose restart
   ```

2. **Port conflicts**
   ```bash
   # Check port usage
   netstat -tulpn | grep :3000
   
   # Modify ports in docker-compose.yml
   ports:
     - "3001:3000"  # Change host port
   ```

3. **Database connection issues**
   ```bash
   # Check PostgreSQL status
   docker-compose exec postgres pg_isready -U postgres
   
   # Check network connectivity
   docker-compose exec backend ping postgres
   ```

4. **Memory issues**
   ```bash
   # Check memory usage
   docker stats
   
   # Increase memory limits
   deploy:
     resources:
       limits:
         memory: 4G
   ```

### Debugging

1. **Access service shell**
   ```bash
   # Backend shell
   docker-compose exec backend bash
   
   # Database shell
   docker-compose exec postgres psql -U postgres
   ```

2. **View real-time logs**
   ```bash
   # All services
   docker-compose logs -f
   
   # Specific service
   docker-compose logs -f backend
   ```

3. **Inspect containers**
   ```bash
   # Container details
   docker inspect dev-pynode-backend-1
   
   # Container processes
   docker-compose exec backend ps aux
   ```

## Performance Optimization

### Resource Limits

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
        reservations:
          memory: 1G
          cpus: '0.5'
```

### Caching

```yaml
services:
  redis:
    command: redis-server --maxmemory 512mb --maxmemory-policy allkeys-lru
    deploy:
      resources:
        limits:
          memory: 512M
```

### Database Optimization

```yaml
services:
  postgres:
    environment:
      - POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C
    command: postgres -c shared_buffers=256MB -c max_connections=100
```

## Maintenance

### Updates

```bash
# Pull latest images
docker-compose pull

# Rebuild and restart
docker-compose up -d --build

# Clean up old images
docker image prune -f
```

### Monitoring

```bash
# Service status
docker-compose ps

# Resource usage
docker stats

# Log analysis
docker-compose logs --tail=100 backend
```

## Next Steps

- [Kubernetes Deployment](kubernetes-deployment.md) - Deploy to Kubernetes
- [CI/CD Pipeline](cicd-pipeline.md) - Automated deployment
- [Monitoring](monitoring.md) - Production monitoring
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
