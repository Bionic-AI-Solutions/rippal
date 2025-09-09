# Configuration Guide

This guide covers all configuration options for Dev-PyNode.

## Environment Variables

Dev-PyNode uses environment variables for configuration. Copy `.env.example` to `.env` and customize as needed.

### Application Configuration

```bash
# Basic application settings
NODE_ENV=development                    # Environment: development, staging, production
APP_NAME=dev-pynode                    # Application name
APP_VERSION=1.0.0                      # Application version
APP_PORT=3000                          # Port for the backend API
APP_HOST=0.0.0.0                       # Host to bind to
DEBUG=true                             # Enable debug mode
```

### Database Configuration

#### PostgreSQL

```bash
# Primary database connection
DB_HOST=postgres                       # Database host
DB_PORT=5432                          # Database port
DB_NAME=dev_template_db                 # Database name
DB_USER=postgres                      # Database user
DB_PASSWORD=postgres_password         # Database password
DB_SSL=false                          # Enable SSL connection
DB_POOL_MIN=2                         # Minimum connection pool size
DB_POOL_MAX=10                        # Maximum connection pool size
DB_CONNECTION_TIMEOUT=60000           # Connection timeout in ms

# Alternative connection string format
DATABASE_URL=postgresql://postgres:postgres_password@postgres:5432/dev_template_db
```

#### Redis

```bash
# Redis cache configuration
REDIS_HOST=redis                      # Redis host
REDIS_PORT=6379                       # Redis port
REDIS_PASSWORD=redis_password         # Redis password
REDIS_DB=0                           # Redis database number
REDIS_URL=redis://:redis_password@redis:6379/0

# Connection pool settings
REDIS_POOL_SIZE=10                   # Connection pool size
REDIS_CONNECT_TIMEOUT=10000          # Connection timeout
REDIS_COMMAND_TIMEOUT=5000           # Command timeout

# Cluster configuration (optional)
REDIS_CLUSTER_ENABLED=false          # Enable Redis cluster
REDIS_CLUSTER_NODES=redis:7000,redis:7001,redis:7002
```

### AI Services Configuration

#### OpenAI API

```bash
# OpenAI configuration
OPENAI_API_KEY=sk-your-openai-api-key-here
OPENAI_MODEL=gpt-4                    # Default model
OPENAI_MAX_TOKENS=2000               # Maximum tokens per request
OPENAI_TEMPERATURE=0.7               # Response randomness (0-1)
OPENAI_TOP_P=1.0                     # Nucleus sampling
OPENAI_FREQUENCY_PENALTY=0.0         # Frequency penalty
OPENAI_PRESENCE_PENALTY=0.0          # Presence penalty
OPENAI_TIMEOUT=30000                 # Request timeout in ms
OPENAI_ORGANIZATION=org-your-org-id  # Organization ID (optional)
```

#### Local AI (Ollama)

```bash
# Local AI server configuration
LOCAL_AI_BASE_URL=http://ollama:11434
LOCAL_AI_API_KEY=your-local-ai-api-key
LOCAL_AI_MODEL=llama2                 # Default local model
LOCAL_AI_TIMEOUT=60000               # Request timeout

# Model parameters
LOCAL_AI_MAX_TOKENS=2000
LOCAL_AI_TEMPERATURE=0.7
LOCAL_AI_TOP_P=0.9
LOCAL_AI_TOP_K=40

# Alternative providers
OLLAMA_BASE_URL=http://ollama:11434
OLLAMA_MODEL=llama2
LM_STUDIO_BASE_URL=http://localhost:1234
LM_STUDIO_MODEL=local-model
```

### Storage Configuration

#### MinIO (S3-Compatible)

```bash
# MinIO configuration
MINIO_ENDPOINT=minio                  # MinIO server endpoint
MINIO_PORT=9000                      # MinIO port
MINIO_ACCESS_KEY=minioadmin          # Access key
MINIO_SECRET_KEY=minioadmin123       # Secret key
MINIO_USE_SSL=false                  # Enable SSL
MINIO_REGION=us-east-1               # Region
MINIO_BUCKET_NAME=dev-pynode-storage # Default bucket
MINIO_BUCKET_REGION=us-east-1        # Bucket region
MINIO_CONSOLE_PORT=9001              # Console port
```

#### AWS S3 (Alternative)

```bash
# AWS S3 configuration
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_REGION=us-east-1
AWS_S3_BUCKET=dev-pynode-storage
```

### Security Configuration

```bash
# JWT Authentication
JWT_SECRET=your-super-secret-jwt-key-min-32-chars-dev-pynode-2024
JWT_EXPIRES_IN=7d                    # Token expiration
JWT_REFRESH_EXPIRES_IN=30d           # Refresh token expiration

# Encryption
ENCRYPTION_KEY=your-32-char-encryption-key-here-dev-pynode-2024
HASH_ROUNDS=12                       # Bcrypt rounds

# CORS
CORS_ORIGIN=http://localhost:3000,http://localhost:3001
CORS_CREDENTIALS=true
```

### Logging Configuration

```bash
# Logging settings
LOG_LEVEL=info                       # Log level: debug, info, warn, error
LOG_FORMAT=json                      # Log format: json, text
LOG_FILE_ENABLED=true                # Enable file logging
LOG_FILE_PATH=./logs/app.log         # Log file path
LOG_MAX_FILES=5                      # Maximum log files
LOG_MAX_SIZE=10m                     # Maximum log file size

# Error tracking
SENTRY_DSN=your-sentry-dsn-here
SENTRY_ENVIRONMENT=development
```

### Rate Limiting

```bash
# Rate limiting configuration
RATE_LIMIT_WINDOW_MS=900000          # Time window in ms (15 minutes)
RATE_LIMIT_MAX_REQUESTS=100          # Max requests per window
RATE_LIMIT_SKIP_SUCCESSFUL_REQUESTS=false
```

### WebSocket Configuration

```bash
# WebSocket settings
WS_ENABLED=true                      # Enable WebSocket support
WS_PORT=3001                         # WebSocket port
WS_CORS_ORIGIN=http://localhost:3000
```

## Configuration Files

### Docker Compose

The `docker-compose.yml` file configures all services. Key sections:

```yaml
services:
  backend:
    environment:
      - NODE_ENV=development
    env_file:
      - .env
    volumes:
      - ./backend:/app/backend
      - /opt/ai-models:/opt/ai-models:ro
```

### Kubernetes

Kubernetes configuration is managed through Kustomize:

```bash
# Base configuration
k8s/base/configmap.yaml

# Environment-specific overrides
k8s/overlays/development/kustomization.yaml
k8s/overlays/production/kustomization.yaml
```

### Package Configuration

#### Node.js (package.json)

```json
{
  "scripts": {
    "start": "node dist/index.js",
    "dev": "nodemon src/index.js",
    "test": "jest"
  }
}
```

#### Python (requirements.txt)

```
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
```

## Environment-Specific Configuration

### Development

```bash
NODE_ENV=development
DEBUG=true
LOG_LEVEL=debug
SENTRY_ENVIRONMENT=development
```

### Staging

```bash
NODE_ENV=staging
DEBUG=false
LOG_LEVEL=info
SENTRY_ENVIRONMENT=staging
```

### Production

```bash
NODE_ENV=production
DEBUG=false
LOG_LEVEL=warn
SENTRY_ENVIRONMENT=production
```

## Configuration Validation

### Environment Validation

The application validates environment variables on startup:

```bash
# Check configuration
npm run config:validate

# Expected output:
# ✅ All required environment variables are set
# ✅ Database connection successful
# ✅ Redis connection successful
# ✅ MinIO connection successful
```

### Configuration Testing

```bash
# Test database connection
npm run test:db

# Test Redis connection
npm run test:redis

# Test MinIO connection
npm run test:storage

# Test AI services
npm run test:ai
```

## Security Best Practices

### Environment Variables

1. **Never commit `.env` files**
2. **Use strong, unique secrets**
3. **Rotate secrets regularly**
4. **Use different secrets per environment**

### Database Security

```bash
# Use strong passwords
DB_PASSWORD=$(openssl rand -base64 32)

# Enable SSL in production
DB_SSL=true

# Use connection pooling
DB_POOL_MIN=5
DB_POOL_MAX=20
```

### API Security

```bash
# Use strong JWT secrets
JWT_SECRET=$(openssl rand -base64 64)

# Set appropriate expiration times
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# Enable rate limiting
RATE_LIMIT_MAX_REQUESTS=100
```

## Configuration Management

### Using ConfigMaps (Kubernetes)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dev-pynode-config
data:
  NODE_ENV: "production"
  LOG_LEVEL: "info"
```

### Using Secrets (Kubernetes)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: dev-pynode-secrets
type: Opaque
stringData:
  DB_PASSWORD: "your-secure-password"
  JWT_SECRET: "your-jwt-secret"
```

## Troubleshooting Configuration

### Common Issues

1. **Missing environment variables**
   ```bash
   # Check required variables
   npm run config:check
   ```

2. **Database connection failures**
   ```bash
   # Test connection
   docker-compose exec postgres pg_isready -U postgres
   ```

3. **Redis connection issues**
   ```bash
   # Test Redis
   docker-compose exec redis redis-cli ping
   ```

4. **Port conflicts**
   ```bash
   # Check port usage
   netstat -tulpn | grep :3000
   ```

### Configuration Debugging

```bash
# Enable debug logging
LOG_LEVEL=debug

# View configuration
npm run config:show

# Validate configuration
npm run config:validate
```

## Next Steps

- [API Reference](api-reference.md) - Learn about the API endpoints
- [Development Guide](development.md) - Advanced development setup
- [Deployment Guide](deployment.md) - Production deployment
- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions
