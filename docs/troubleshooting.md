# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with Dev-PyNode.

## Quick Diagnostics

### Health Check Commands

```bash
# Check all services status
docker-compose ps

# Check application health
curl http://localhost:3000/health

# Check database connectivity
docker-compose exec postgres pg_isready -U postgres

# Check Redis connectivity
docker-compose exec redis redis-cli ping

# Check MinIO connectivity
curl http://localhost:9000/minio/health/live
```

### Log Analysis

```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs backend
docker-compose logs postgres
docker-compose logs redis

# Follow logs in real-time
docker-compose logs -f backend

# View last 100 lines
docker-compose logs --tail=100 backend
```

## Common Issues

### 1. Services Not Starting

#### Symptoms
- Services show as "Exited" or "Restarting"
- Error messages in logs
- Port conflicts

#### Diagnosis
```bash
# Check service status
docker-compose ps

# Check resource usage
docker stats

# Check port conflicts
netstat -tulpn | grep :3000
```

#### Solutions

**Port Conflicts**:
```bash
# Kill process using port
sudo kill -9 $(lsof -t -i:3000)

# Or change port in docker-compose.yml
ports:
  - "3001:3000"  # Change host port
```

**Resource Issues**:
```bash
# Increase memory limits
deploy:
  resources:
    limits:
      memory: 4G
    reservations:
      memory: 2G
```

**Permission Issues**:
```bash
# Fix file permissions
sudo chown -R $USER:$USER .

# Fix Docker permissions
sudo usermod -aG docker $USER
# Log out and log back in
```

### 2. Database Connection Issues

#### Symptoms
- "Connection refused" errors
- "Database not found" errors
- Slow query performance

#### Diagnosis
```bash
# Check PostgreSQL status
docker-compose exec postgres pg_isready -U postgres

# Check database logs
docker-compose logs postgres

# Test connection
docker-compose exec postgres psql -U postgres -d dev_template_db -c "SELECT 1;"
```

#### Solutions

**Database Not Ready**:
```bash
# Wait for database to be ready
until docker-compose exec postgres pg_isready -U postgres; do
  echo "Waiting for database..."
  sleep 2
done
```

**Connection Pool Exhausted**:
```bash
# Check active connections
docker-compose exec postgres psql -U postgres -c "
SELECT count(*) as active_connections 
FROM pg_stat_activity 
WHERE state = 'active';"

# Increase pool size in .env
DB_POOL_MAX=20
```

**Database Corruption**:
```bash
# Reset database
docker-compose down -v
docker-compose up -d

# Or restore from backup
docker-compose exec -T postgres psql -U postgres dev_template_db < backup.sql
```

### 3. Redis Connection Issues

#### Symptoms
- "Connection refused" to Redis
- Cache misses
- Session storage failures

#### Diagnosis
```bash
# Check Redis status
docker-compose exec redis redis-cli ping

# Check Redis logs
docker-compose logs redis

# Check Redis memory usage
docker-compose exec redis redis-cli info memory
```

#### Solutions

**Redis Not Responding**:
```bash
# Restart Redis
docker-compose restart redis

# Check Redis configuration
docker-compose exec redis redis-cli config get "*"
```

**Memory Issues**:
```bash
# Clear Redis cache
docker-compose exec redis redis-cli flushall

# Increase memory limit
deploy:
  resources:
    limits:
      memory: 1G
```

### 4. AI Service Issues

#### Symptoms
- AI requests timing out
- "Model not found" errors
- Poor response quality

#### Diagnosis
```bash
# Check Ollama status
curl http://localhost:11434/api/tags

# Check available models
docker-compose exec ollama ollama list

# Test AI service
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello"}'
```

#### Solutions

**Model Not Available**:
```bash
# Pull required model
docker-compose exec ollama ollama pull llama2

# Check model status
docker-compose exec ollama ollama show llama2
```

**API Key Issues**:
```bash
# Verify OpenAI API key
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
  https://api.openai.com/v1/models

# Update API key in .env
OPENAI_API_KEY=your-new-api-key
```

**Memory Issues**:
```bash
# Check GPU memory (if using GPU)
nvidia-smi

# Reduce model size or use CPU
OLLAMA_GPU_LAYERS=0
```

### 5. File Upload Issues

#### Symptoms
- File uploads failing
- "Storage not available" errors
- Slow upload speeds

#### Diagnosis
```bash
# Check MinIO status
curl http://localhost:9000/minio/health/live

# Check MinIO logs
docker-compose logs minio

# Test file upload
curl -X POST http://localhost:3000/api/files/upload \
  -F "file=@test.txt"
```

#### Solutions

**Storage Full**:
```bash
# Check disk usage
df -h

# Clean up old files
docker-compose exec minio mc ls minio/dev-pynode-storage

# Increase storage
volumes:
  minio_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /path/to/larger/storage
```

**Permission Issues**:
```bash
# Fix MinIO permissions
docker-compose exec minio chown -R minio:minio /data

# Check bucket policy
docker-compose exec minio mc policy get minio/dev-pynode-storage
```

### 6. Authentication Issues

#### Symptoms
- Login failures
- "Invalid token" errors
- Session timeouts

#### Diagnosis
```bash
# Check JWT secret
echo $JWT_SECRET

# Test authentication endpoint
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password"}'

# Check Redis for sessions
docker-compose exec redis redis-cli keys "session:*"
```

#### Solutions

**JWT Secret Issues**:
```bash
# Generate new JWT secret
JWT_SECRET=$(openssl rand -base64 64)

# Update .env file
echo "JWT_SECRET=$JWT_SECRET" >> .env
```

**Session Storage Issues**:
```bash
# Clear session cache
docker-compose exec redis redis-cli flushdb

# Check Redis connectivity
docker-compose exec redis redis-cli ping
```

## Performance Issues

### 1. Slow API Responses

#### Diagnosis
```bash
# Check response times
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:3000/health

# Check database query performance
docker-compose exec postgres psql -U postgres -c "
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;"
```

#### Solutions

**Database Optimization**:
```sql
-- Add missing indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_chat_messages_user_date ON chat_messages(user_id, created_at);

-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';
```

**Caching**:
```bash
# Enable Redis caching
REDIS_CACHE_ENABLED=true

# Check cache hit ratio
docker-compose exec redis redis-cli info stats | grep keyspace
```

### 2. High Memory Usage

#### Diagnosis
```bash
# Check memory usage
docker stats

# Check specific container
docker-compose exec backend ps aux

# Check memory leaks
docker-compose exec backend node --inspect=0.0.0.0:9229 src/index.js
```

#### Solutions

**Memory Leaks**:
```bash
# Restart services
docker-compose restart

# Increase memory limits
deploy:
  resources:
    limits:
      memory: 4G
```

**Garbage Collection**:
```bash
# Enable GC logging
NODE_OPTIONS="--max-old-space-size=4096 --gc-interval=100"

# Monitor GC
docker-compose exec backend node --trace-gc src/index.js
```

### 3. High CPU Usage

#### Diagnosis
```bash
# Check CPU usage
docker stats

# Check process CPU usage
docker-compose exec backend top

# Profile Node.js application
docker-compose exec backend node --prof src/index.js
```

#### Solutions

**CPU Optimization**:
```bash
# Increase CPU limits
deploy:
  resources:
    limits:
      cpu: "2.0"
    reservations:
      cpu: "1.0"
```

**Code Optimization**:
```bash
# Enable CPU profiling
NODE_OPTIONS="--prof"

# Analyze profile
node --prof-process isolate-*.log
```

## Network Issues

### 1. Connection Timeouts

#### Diagnosis
```bash
# Check network connectivity
docker-compose exec backend ping postgres
docker-compose exec backend ping redis

# Check DNS resolution
docker-compose exec backend nslookup postgres
```

#### Solutions

**Network Configuration**:
```yaml
# Add network aliases
networks:
  dev-pynode-network:
    aliases:
      - postgres
      - redis
      - minio
```

**Timeout Configuration**:
```bash
# Increase timeouts
DB_CONNECTION_TIMEOUT=60000
REDIS_CONNECT_TIMEOUT=10000
```

### 2. Port Conflicts

#### Diagnosis
```bash
# Check port usage
netstat -tulpn | grep :3000
lsof -i :3000

# Check Docker port mapping
docker-compose ps
```

#### Solutions

**Change Ports**:
```yaml
# Update docker-compose.yml
ports:
  - "3001:3000"  # Change host port
  - "3002:3001"  # Change WebSocket port
```

**Kill Conflicting Processes**:
```bash
# Kill process using port
sudo kill -9 $(lsof -t -i:3000)

# Or use different ports
```

## Kubernetes Issues

### 1. Pods Not Starting

#### Diagnosis
```bash
# Check pod status
kubectl get pods -n dev-pynode

# Check pod logs
kubectl logs -f deployment/dev-pynode -n dev-pynode

# Check pod events
kubectl describe pod <pod-name> -n dev-pynode
```

#### Solutions

**Resource Issues**:
```yaml
# Increase resource limits
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

**Image Issues**:
```bash
# Check image availability
kubectl describe pod <pod-name> -n dev-pynode | grep -i image

# Pull image manually
docker pull bionic-ai-solutions/dev-pynode:latest
```

### 2. Service Not Accessible

#### Diagnosis
```bash
# Check service status
kubectl get svc -n dev-pynode

# Check endpoints
kubectl get endpoints -n dev-pynode

# Test service connectivity
kubectl run test-pod --image=busybox -it --rm -- nslookup dev-pynode-service
```

#### Solutions

**Service Configuration**:
```yaml
# Check service selector
spec:
  selector:
    app: dev-pynode  # Must match pod labels
```

**Network Policies**:
```bash
# Check network policies
kubectl get networkpolicies -n dev-pynode

# Temporarily disable network policies
kubectl delete networkpolicy dev-pynode-network-policy -n dev-pynode
```

### 3. Ingress Issues

#### Diagnosis
```bash
# Check ingress status
kubectl get ingress -n dev-pynode

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress logs
kubectl logs -f deployment/ingress-nginx-controller -n ingress-nginx
```

#### Solutions

**Ingress Configuration**:
```yaml
# Check ingress annotations
annotations:
  kubernetes.io/ingress.class: "nginx"
  nginx.ingress.kubernetes.io/ssl-redirect: "true"
```

**DNS Issues**:
```bash
# Check DNS resolution
nslookup api.dev-pynode.example.com

# Update DNS records
# Point domain to ingress controller IP
```

## Monitoring and Debugging

### 1. Application Monitoring

#### Prometheus Metrics
```bash
# Check metrics endpoint
curl http://localhost:3000/metrics

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets
```

#### Grafana Dashboards
```bash
# Access Grafana
open http://localhost:3001
# Login: admin/admin123

# Check dashboard data
curl http://localhost:3001/api/dashboards/db/dev-pynode
```

### 2. Log Analysis

#### Centralized Logging
```bash
# Check ELK stack (if deployed)
curl http://localhost:9200/_cluster/health

# Search logs
curl -X GET "localhost:9200/logs/_search?q=error"
```

#### Log Aggregation
```bash
# Aggregate error logs
docker-compose logs | grep -i error | tail -100

# Count error occurrences
docker-compose logs | grep -i error | wc -l
```

### 3. Performance Profiling

#### Node.js Profiling
```bash
# Enable profiling
NODE_OPTIONS="--prof" docker-compose up

# Analyze profile
node --prof-process isolate-*.log
```

#### Python Profiling
```bash
# Profile Python services
docker-compose exec backend python -m cProfile -o profile.stats app/main.py

# Analyze profile
docker-compose exec backend python -c "
import pstats
p = pstats.Stats('profile.stats')
p.sort_stats('cumulative').print_stats(10)
"
```

## Recovery Procedures

### 1. Database Recovery

#### Backup Restoration
```bash
# Stop application
docker-compose stop backend

# Restore database
docker-compose exec -T postgres psql -U postgres dev_template_db < backup.sql

# Start application
docker-compose start backend
```

#### Point-in-Time Recovery
```bash
# Enable WAL archiving
echo "wal_level = replica" >> postgresql.conf
echo "archive_mode = on" >> postgresql.conf

# Restore to specific time
pg_basebackup -D /backup -Ft -z -P
```

### 2. File Storage Recovery

#### MinIO Recovery
```bash
# Check MinIO status
docker-compose exec minio mc admin info minio

# Restore from backup
docker-compose exec minio mc mirror /backup/minio/ /data/
```

#### S3 Recovery
```bash
# Sync from S3 backup
aws s3 sync s3://backup-bucket/ /restore/path/
```

### 3. Application Recovery

#### Rollback Deployment
```bash
# Kubernetes rollback
kubectl rollout undo deployment/dev-pynode -n dev-pynode

# Docker rollback
docker-compose down
docker-compose -f docker-compose.yml -f docker-compose.previous.yml up -d
```

#### Configuration Recovery
```bash
# Restore configuration
cp .env.backup .env
cp docker-compose.yml.backup docker-compose.yml

# Restart services
docker-compose restart
```

## Prevention Strategies

### 1. Monitoring Setup

#### Health Checks
```yaml
# Add comprehensive health checks
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

#### Alerting
```yaml
# Prometheus alerting rules
groups:
- name: dev-pynode
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
```

### 2. Backup Strategy

#### Automated Backups
```bash
#!/bin/bash
# backup.sh

# Database backup
docker-compose exec -T postgres pg_dump -U postgres dev_template_db | gzip > "backup/db_$(date +%Y%m%d_%H%M%S).sql.gz"

# File backup
docker-compose exec minio mc mirror /data "backup/files_$(date +%Y%m%d_%H%M%S)/"

# Cleanup old backups
find backup/ -name "*.gz" -mtime +7 -delete
```

#### Backup Verification
```bash
# Verify database backup
gunzip -c backup/db_*.sql.gz | head -20

# Verify file backup
docker-compose exec minio mc ls backup/files_*/
```

### 3. Testing

#### Load Testing
```bash
# Install artillery
npm install -g artillery

# Run load test
artillery run load-test.yml
```

#### Chaos Engineering
```bash
# Install chaos monkey
kubectl apply -f chaos-monkey.yaml

# Simulate failures
kubectl delete pod -l app=dev-pynode --grace-period=0
```

## Getting Help

### 1. Documentation
- [Installation Guide](installation.md)
- [Configuration Guide](configuration.md)
- [API Reference](api-reference.md)
- [Architecture Documentation](architecture.md)

### 2. Community Support
- [GitHub Issues](https://github.com/Bionic-AI-Solutions/dev-pynode/issues)
- [GitHub Discussions](https://github.com/Bionic-AI-Solutions/dev-pynode/discussions)
- [Discord Server](https://discord.gg/bionic-ai-solutions)

### 3. Professional Support
- Contact: support@bionic-ai-solutions.com
- Documentation: https://docs.bionic-ai-solutions.com
- Status Page: https://status.bionic-ai-solutions.com

## Next Steps

- [Installation Guide](installation.md) - Fresh installation
- [Configuration Guide](configuration.md) - System configuration
- [Development Guide](development.md) - Development setup
- [Monitoring Guide](monitoring.md) - System monitoring
