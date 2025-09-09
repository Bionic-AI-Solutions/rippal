# Kubernetes Deployment Guide

This guide covers deploying Dev-PyNode to Kubernetes clusters.

## Prerequisites

- Kubernetes cluster (1.28+)
- kubectl configured
- Helm 3.0+ (optional)
- Docker registry access

## Quick Start

### 1. Prepare Kubernetes Cluster

```bash
# Verify cluster access
kubectl cluster-info

# Check available nodes
kubectl get nodes

# Verify storage class
kubectl get storageclass
```

### 2. Deploy to Development

```bash
# Deploy base configuration
kubectl apply -k k8s/base

# Deploy development overlay
kubectl apply -k k8s/overlays/development

# Check deployment status
kubectl get pods -n dev-pynode
```

### 3. Access the Application

```bash
# Port forward to access services
kubectl port-forward svc/dev-pynode-service 3000:3000 -n dev-pynode

# Access the application
open http://localhost:3000
```

## Cluster Requirements

### Minimum Requirements

- **CPU**: 4 cores
- **Memory**: 8GB RAM
- **Storage**: 50GB
- **Nodes**: 3 nodes minimum

### Recommended Requirements

- **CPU**: 8 cores
- **Memory**: 16GB RAM
- **Storage**: 100GB SSD
- **Nodes**: 5 nodes

### Required Components

- **Ingress Controller**: NGINX, Traefik, or similar
- **Storage Class**: For persistent volumes
- **Load Balancer**: For external access
- **Cert Manager**: For SSL certificates (optional)

## Configuration

### Environment-Specific Configurations

#### Development

```bash
# Deploy development environment
kubectl apply -k k8s/overlays/development

# Features:
# - Single replica
# - Debug logging
# - Development database
# - No SSL
```

#### Staging

```bash
# Deploy staging environment
kubectl apply -k k8s/overlays/staging

# Features:
# - 2 replicas
# - Production-like configuration
# - SSL enabled
# - Monitoring enabled
```

#### Production

```bash
# Deploy production environment
kubectl apply -k k8s/overlays/production

# Features:
# - 3+ replicas
# - Production database
# - SSL/TLS
# - Full monitoring
# - Resource limits
```

## Service Configuration

### Backend Service

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-pynode
  namespace: dev-pynode
spec:
  replicas: 3
  selector:
    matchLabels:
      app: dev-pynode
  template:
    spec:
      containers:
      - name: dev-pynode
        image: bionic-ai-solutions/dev-pynode:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Database Service

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: dev-pynode
spec:
  serviceName: postgres-service
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: "dev_template_db"
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 20Gi
```

## Ingress Configuration

### NGINX Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dev-pynode-ingress
  namespace: dev-pynode
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - api.dev-pynode.example.com
    secretName: dev-pynode-tls
  rules:
  - host: api.dev-pynode.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: dev-pynode-service
            port:
              number: 3000
```

### Traefik Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dev-pynode-ingress
  namespace: dev-pynode
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  tls:
  - secretName: dev-pynode-tls
  rules:
  - host: api.dev-pynode.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: dev-pynode-service
            port:
              number: 3000
```

## Secrets Management

### Creating Secrets

```bash
# Create database secret
kubectl create secret generic postgres-secret \
  --from-literal=password=your-secure-password \
  -n dev-pynode

# Create JWT secret
kubectl create secret generic jwt-secret \
  --from-literal=secret=your-jwt-secret \
  -n dev-pynode

# Create OpenAI API key secret
kubectl create secret generic openai-secret \
  --from-literal=api-key=your-openai-key \
  -n dev-pynode
```

### Using Secrets in Deployments

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-pynode
spec:
  template:
    spec:
      containers:
      - name: dev-pynode
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: jwt-secret
              key: secret
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: openai-secret
              key: api-key
```

## ConfigMaps

### Application Configuration

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dev-pynode-config
  namespace: dev-pynode
data:
  NODE_ENV: "production"
  LOG_LEVEL: "info"
  DB_HOST: "postgres-service"
  DB_PORT: "5432"
  REDIS_HOST: "redis-service"
  REDIS_PORT: "6379"
  MINIO_ENDPOINT: "minio-service"
  MINIO_PORT: "9000"
```

### Using ConfigMaps

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-pynode
spec:
  template:
    spec:
      containers:
      - name: dev-pynode
        envFrom:
        - configMapRef:
            name: dev-pynode-config
```

## Storage

### Persistent Volumes

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: dev-pynode
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: fast-ssd
```

### Storage Classes

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
reclaimPolicy: Retain
allowVolumeExpansion: true
```

## Monitoring

### Prometheus Integration

```yaml
apiVersion: v1
kind: ServiceMonitor
metadata:
  name: dev-pynode-metrics
  namespace: dev-pynode
spec:
  selector:
    matchLabels:
      app: dev-pynode
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

### Grafana Dashboard

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dev-pynode-dashboard
  namespace: monitoring
data:
  dashboard.json: |
    {
      "dashboard": {
        "title": "Dev-PyNode Dashboard",
        "panels": [
          {
            "title": "Request Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(http_requests_total[5m])",
                "legendFormat": "{{method}} {{endpoint}}"
              }
            ]
          }
        ]
      }
    }
```

## Scaling

### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: dev-pynode-hpa
  namespace: dev-pynode
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: dev-pynode
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Vertical Pod Autoscaler

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: dev-pynode-vpa
  namespace: dev-pynode
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: dev-pynode
  updatePolicy:
    updateMode: "Auto"
```

## Security

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: dev-pynode-network-policy
  namespace: dev-pynode
spec:
  podSelector:
    matchLabels:
      app: dev-pynode
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 3000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
```

### Pod Security Standards

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev-pynode
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### RBAC

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: dev-pynode-role
  namespace: dev-pynode
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-pynode-rolebinding
  namespace: dev-pynode
subjects:
- kind: ServiceAccount
  name: dev-pynode
  namespace: dev-pynode
roleRef:
  kind: Role
  name: dev-pynode-role
  apiGroup: rbac.authorization.k8s.io
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Deploy to Kubernetes
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure kubectl
      run: |
        echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig
        export KUBECONFIG=kubeconfig
    
    - name: Deploy to production
      run: |
        kubectl apply -k k8s/overlays/production
        kubectl rollout status deployment/dev-pynode -n dev-pynode
```

### ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dev-pynode
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Bionic-AI-Solutions/dev-pynode
    targetRevision: HEAD
    path: k8s/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: dev-pynode
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Troubleshooting

### Common Issues

1. **Pods not starting**
   ```bash
   # Check pod status
   kubectl get pods -n dev-pynode
   
   # Check pod logs
   kubectl logs -f deployment/dev-pynode -n dev-pynode
   
   # Check pod events
   kubectl describe pod <pod-name> -n dev-pynode
   ```

2. **Service not accessible**
   ```bash
   # Check service status
   kubectl get svc -n dev-pynode
   
   # Check endpoints
   kubectl get endpoints -n dev-pynode
   
   # Test service connectivity
   kubectl run test-pod --image=busybox -it --rm -- nslookup dev-pynode-service
   ```

3. **Ingress not working**
   ```bash
   # Check ingress status
   kubectl get ingress -n dev-pynode
   
   # Check ingress controller
   kubectl get pods -n ingress-nginx
   
   # Check ingress logs
   kubectl logs -f deployment/ingress-nginx-controller -n ingress-nginx
   ```

4. **Storage issues**
   ```bash
   # Check PVC status
   kubectl get pvc -n dev-pynode
   
   # Check PV status
   kubectl get pv
   
   # Check storage class
   kubectl get storageclass
   ```

### Debugging Commands

```bash
# Get all resources
kubectl get all -n dev-pynode

# Check resource usage
kubectl top pods -n dev-pynode
kubectl top nodes

# Check events
kubectl get events -n dev-pynode --sort-by='.lastTimestamp'

# Port forward for debugging
kubectl port-forward svc/dev-pynode-service 3000:3000 -n dev-pynode

# Execute commands in pod
kubectl exec -it deployment/dev-pynode -n dev-pynode -- bash
```

## Performance Optimization

### Resource Optimization

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-pynode
spec:
  template:
    spec:
      containers:
      - name: dev-pynode
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        # Enable CPU throttling
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1001
```

### Node Affinity

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-pynode
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-type
                operator: In
                values:
                - compute-optimized
```

## Backup and Recovery

### Database Backup

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: dev-pynode
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: postgres-backup
            image: postgres:15-alpine
            command:
            - /bin/bash
            - -c
            - |
              pg_dump -h postgres-service -U postgres dev_template_db | gzip > /backup/backup-$(date +%Y%m%d).sql.gz
            env:
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

## Next Steps

- [Docker Deployment](docker-deployment.md) - Local development with Docker
- [CI/CD Pipeline](cicd-pipeline.md) - Automated deployment
- [Monitoring](monitoring.md) - Production monitoring
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
