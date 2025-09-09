# Monitoring Guide

This guide covers monitoring, observability, and alerting for Dev-PyNode.

## Overview

Dev-PyNode includes comprehensive monitoring with:
- **Prometheus** for metrics collection
- **Grafana** for visualization and dashboards
- **Structured logging** with JSON format
- **Health checks** for all services
- **Alerting** for critical issues

## Monitoring Stack

### Prometheus

**Purpose**: Metrics collection and storage

**Configuration**:
```yaml
# docker-compose.yml
prometheus:
  image: prom/prometheus:latest
  ports:
    - "9090:9090"
  volumes:
    - ./docker/prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus_data:/prometheus
  command:
    - '--config.file=/etc/prometheus/prometheus.yml'
    - '--storage.tsdb.path=/prometheus'
    - '--web.console.libraries=/etc/prometheus/console_libraries'
    - '--web.console.templates=/etc/prometheus/consoles'
    - '--storage.tsdb.retention.time=200h'
    - '--web.enable-lifecycle'
```

**Prometheus Configuration**:
```yaml
# docker/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'dev-pynode'
    static_configs:
      - targets: ['backend:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']

  - job_name: 'minio'
    static_configs:
      - targets: ['minio:9000']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

### Grafana

**Purpose**: Visualization and dashboards

**Configuration**:
```yaml
# docker-compose.yml
grafana:
  image: grafana/grafana:latest
  ports:
    - "3001:3000"
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=admin123
    - GF_USERS_ALLOW_SIGN_UP=false
  volumes:
    - grafana_data:/var/lib/grafana
    - ./docker/grafana/provisioning:/etc/grafana/provisioning:ro
```

**Dashboard Configuration**:
```yaml
# docker/grafana/provisioning/dashboards/dashboard.yml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
```

## Key Metrics

### Application Metrics

#### HTTP Metrics
```javascript
// Backend metrics
const promClient = require('prom-client');

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10]
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const activeConnections = new promClient.Gauge({
  name: 'active_connections',
  help: 'Number of active connections'
});
```

#### Database Metrics
```javascript
const dbConnections = new promClient.Gauge({
  name: 'database_connections_active',
  help: 'Number of active database connections',
  labelNames: ['database']
});

const dbQueryDuration = new promClient.Histogram({
  name: 'database_query_duration_seconds',
  help: 'Duration of database queries in seconds',
  labelNames: ['query_type', 'table']
});
```

#### AI Service Metrics
```javascript
const aiRequestsTotal = new promClient.Counter({
  name: 'ai_requests_total',
  help: 'Total number of AI requests',
  labelNames: ['model', 'provider', 'status']
});

const aiRequestDuration = new promClient.Histogram({
  name: 'ai_request_duration_seconds',
  help: 'Duration of AI requests in seconds',
  labelNames: ['model', 'provider']
});

const aiTokensUsed = new promClient.Counter({
  name: 'ai_tokens_used_total',
  help: 'Total number of AI tokens used',
  labelNames: ['model', 'provider', 'token_type']
});
```

### Infrastructure Metrics

#### System Metrics
- CPU usage per container
- Memory usage per container
- Disk I/O and network traffic
- Container restart counts

#### Database Metrics
- Connection pool utilization
- Query performance
- Lock waits and deadlocks
- Replication lag

#### Cache Metrics
- Redis memory usage
- Cache hit/miss ratios
- Key expiration rates
- Connection counts

## Dashboards

### Application Dashboard

**Key Panels**:
1. **Request Rate**: Requests per second by endpoint
2. **Response Time**: P50, P95, P99 response times
3. **Error Rate**: 4xx and 5xx error rates
4. **Active Users**: Concurrent active users
5. **AI Usage**: AI requests by model and provider

**Grafana Dashboard JSON**:
```json
{
  "dashboard": {
    "title": "Dev-PyNode Application",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{route}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "P95"
          }
        ]
      }
    ]
  }
}
```

### Infrastructure Dashboard

**Key Panels**:
1. **CPU Usage**: Per container CPU utilization
2. **Memory Usage**: Per container memory usage
3. **Disk I/O**: Read/write operations
4. **Network Traffic**: Inbound/outbound traffic
5. **Container Health**: Restart counts and health status

### Database Dashboard

**Key Panels**:
1. **Connection Pool**: Active/idle connections
2. **Query Performance**: Slow queries and execution times
3. **Database Size**: Table sizes and growth
4. **Lock Waits**: Database locks and waits
5. **Replication**: Replication lag and status

## Alerting

### Alert Rules

```yaml
# docker/prometheus/alert_rules.yml
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
      description: "Error rate is {{ $value }} errors per second"

  - alert: HighResponseTime
    expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High response time"
      description: "95th percentile response time is {{ $value }} seconds"

  - alert: DatabaseConnectionsHigh
    expr: database_connections_active > 80
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High database connections"
      description: "Database connections are at {{ $value }}"

  - alert: RedisMemoryHigh
    expr: redis_memory_used_bytes / redis_memory_max_bytes > 0.8
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High Redis memory usage"
      description: "Redis memory usage is {{ $value }}%"

  - alert: AIServiceDown
    expr: up{job="ai-service"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "AI service is down"
      description: "AI service has been down for more than 1 minute"
```

### AlertManager Configuration

```yaml
# docker/alertmanager/alertmanager.yml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@dev-pynode.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://webhook:5001/'

- name: 'email'
  email_configs:
  - to: 'admin@dev-pynode.com'
    subject: 'Dev-PyNode Alert: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}
```

## Logging

### Structured Logging

```javascript
// Backend logging configuration
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'dev-pynode-backend' },
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});
```

### Log Aggregation

```yaml
# ELK Stack for log aggregation
elasticsearch:
  image: docker.elastic.co/elasticsearch/elasticsearch:8.8.0
  environment:
    - discovery.type=single-node
    - xpack.security.enabled=false
  volumes:
    - elasticsearch_data:/usr/share/elasticsearch/data

logstash:
  image: docker.elastic.co/logstash/logstash:8.8.0
  volumes:
    - ./docker/logstash/pipeline:/usr/share/logstash/pipeline
  depends_on:
    - elasticsearch

kibana:
  image: docker.elastic.co/kibana/kibana:8.8.0
  ports:
    - "5601:5601"
  environment:
    - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
  depends_on:
    - elasticsearch
```

### Logstash Configuration

```ruby
# docker/logstash/pipeline/logstash.conf
input {
  beats {
    port => 5044
  }
}

filter {
  if [fields][service] == "dev-pynode" {
    grok {
      match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:message}" }
    }
    
    date {
      match => [ "timestamp", "ISO8601" ]
    }
    
    mutate {
      add_field => { "service" => "dev-pynode" }
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "dev-pynode-logs-%{+YYYY.MM.dd}"
  }
}
```

## Health Checks

### Application Health Checks

```javascript
// Health check endpoint
app.get('/health', async (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || '1.0.0',
    uptime: process.uptime(),
    services: {}
  };

  try {
    // Check database
    await db.query('SELECT 1');
    health.services.database = 'connected';
  } catch (error) {
    health.services.database = 'disconnected';
    health.status = 'unhealthy';
  }

  try {
    // Check Redis
    await redis.ping();
    health.services.redis = 'connected';
  } catch (error) {
    health.services.redis = 'disconnected';
    health.status = 'unhealthy';
  }

  try {
    // Check MinIO
    await minioClient.bucketExists('dev-pynode-storage');
    health.services.storage = 'connected';
  } catch (error) {
    health.services.storage = 'disconnected';
    health.status = 'unhealthy';
  }

  const statusCode = health.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(health);
});
```

### Kubernetes Health Checks

```yaml
# Kubernetes health checks
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3

startupProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 30
```

## Performance Monitoring

### APM (Application Performance Monitoring)

```javascript
// New Relic integration
const newrelic = require('newrelic');

// Custom metrics
newrelic.recordMetric('Custom/AI/Requests', 1);
newrelic.recordMetric('Custom/AI/TokensUsed', tokenCount);

// Custom events
newrelic.recordCustomEvent('AIRequest', {
  model: 'gpt-4',
  tokens: tokenCount,
  duration: responseTime
});
```

### Distributed Tracing

```javascript
// OpenTelemetry integration
const { NodeTracerProvider } = require('@opentelemetry/node');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');

const tracerProvider = new NodeTracerProvider();
tracerProvider.addSpanProcessor(
  new SimpleSpanProcessor(
    new JaegerExporter({
      endpoint: 'http://jaeger:14268/api/traces'
    })
  )
);
tracerProvider.register();

// Create spans
const tracer = trace.getTracer('dev-pynode');
const span = tracer.startSpan('ai-request');
span.setAttributes({
  'ai.model': 'gpt-4',
  'ai.provider': 'openai'
});
```

## Monitoring Best Practices

### 1. Metric Naming

**Conventions**:
- Use descriptive names: `http_request_duration_seconds`
- Include units: `_seconds`, `_bytes`, `_total`
- Use consistent prefixes: `dev_template_`

### 2. Dashboard Design

**Principles**:
- Keep dashboards focused on specific use cases
- Use consistent color schemes
- Include time ranges and refresh intervals
- Add annotations for deployments and incidents

### 3. Alerting Strategy

**Guidelines**:
- Set appropriate thresholds
- Use different severity levels
- Include runbook links in alerts
- Test alerting channels regularly

### 4. Log Management

**Best Practices**:
- Use structured logging (JSON)
- Include correlation IDs
- Set appropriate log levels
- Implement log rotation

## Troubleshooting Monitoring

### Common Issues

1. **Metrics Not Appearing**
   ```bash
   # Check Prometheus targets
   curl http://localhost:9090/api/v1/targets
   
   # Check metrics endpoint
   curl http://localhost:3000/metrics
   ```

2. **Grafana Not Loading**
   ```bash
   # Check Grafana logs
   docker-compose logs grafana
   
   # Check Prometheus connection
   curl http://localhost:9090/api/v1/query?query=up
   ```

3. **Alerts Not Firing**
   ```bash
   # Check alert rules
   curl http://localhost:9090/api/v1/rules
   
   # Check AlertManager
   curl http://localhost:9093/api/v1/alerts
   ```

## Next Steps

- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions
- [Deployment Guide](deployment.md) - Production deployment
- [Architecture Documentation](architecture.md) - System design
- [Configuration Guide](configuration.md) - System configuration
