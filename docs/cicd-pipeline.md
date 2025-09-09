# CI/CD Pipeline Guide

This guide covers the continuous integration and deployment pipeline for Dev-PyNode.

## Overview

Dev-PyNode uses GitHub Actions for CI/CD with the following pipeline stages:

1. **Code Quality** - Linting, formatting, type checking
2. **Security** - Vulnerability scanning, dependency audit
3. **Testing** - Unit tests, integration tests, e2e tests
4. **Build** - Docker image creation and publishing
5. **Deploy** - Automated deployment to environments
6. **Monitoring** - Health checks and rollback capabilities

## Pipeline Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Code Push     │    │   GitHub        │    │   GitHub        │
│                 │    │   Actions       │    │   Actions       │
│  ┌─────────────┐│    │                 │    │                 │
│  │   Feature   ││───▶│  ┌─────────────┐│    │  ┌─────────────┐│
│  │   Branch    ││    │  │   Quality   ││    │  │   Build     ││
│  └─────────────┘│    │  │   Checks    ││    │  │   & Test    ││
│                 │    │  └─────────────┘│    │  └─────────────┘│
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Security      │    │   Docker Hub    │
                       │   Scanning      │    │   Registry      │
                       └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   ArgoCD        │    │   Kubernetes    │
                       │   GitOps        │    │   Cluster       │
                       └─────────────────┘    └─────────────────┘
```

## GitHub Actions Workflow

### Main Workflow

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  release:
    types: [ published ]

env:
  REGISTRY: docker.io
  IMAGE_NAME: bionic-ai-solutions/dev-pynode
  K8S_NAMESPACE: dev-pynode

jobs:
  # Code Quality and Security Checks
  code-quality:
    name: Code Quality & Security
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0

    - name: Set up Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'

    - name: Install dependencies
      run: |
        npm ci
        pip install -r requirements-dev.txt

    - name: Run ESLint
      run: npm run lint

    - name: Run Prettier check
      run: npm run format:check

    - name: Run TypeScript check
      run: npm run type-check

    - name: Run Python linting
      run: |
        flake8 backend/
        black --check backend/
        isort --check-only backend/

    - name: Run security audit (Node.js)
      run: npm audit --audit-level=moderate

    - name: Run security audit (Python)
      run: bandit -r backend/ -f json -o bandit-report.json

    - name: Upload security reports
      uses: actions/upload-artifact@v3
      with:
        name: security-reports
        path: |
          bandit-report.json
          npm-audit.json
```

### Testing Stage

```yaml
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'

    - name: Install dependencies
      run: |
        npm ci
        pip install -r requirements-dev.txt

    - name: Run unit tests (Node.js)
      run: npm run test:unit
      env:
        NODE_ENV: test
        TEST_DB_NAME: test_db
        TEST_REDIS_DB: 1

    - name: Run unit tests (Python)
      run: pytest tests/unit/ -v --cov=backend --cov-report=xml
      env:
        ENV: test

    - name: Run integration tests
      run: |
        npm run test:integration
        pytest tests/integratione2e/ -v
      env:
        NODE_ENV: test
        ENV: test

    - name: Upload coverage reports
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
        flags: unittests
        name: codecov-umbrella
```

### Build Stage

```yaml
  build:
    name: Build & Push Docker Images
    runs-on: ubuntu-latest
    needs: [code-quality, test]
    if: github.event_name == 'push' || github.event_name == 'release'
    
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
      image-digest: ${{ steps.build.outputs.digest }}

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to Docker Hub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}

    - name: Build and push Docker image
      id: build
      uses: docker/build-push-action@v5
      with:
        context: .
        platforms: linux/amd64,linux/arm64
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
        target: production

    - name: Sign image with Cosign
      uses: sigstore/cosign-installer@v3
      with:
        cosign-release: 'v2.2.0'

    - name: Sign the published Docker image
      run: |
        cosign sign --yes ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build.outputs.digest }}
```

### Deployment Stages

```yaml
  deploy-dev:
    name: Deploy to Development
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/develop'
    environment: development

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'

    - name: Configure kubectl
      run: |
        echo "${{ secrets.KUBE_CONFIG_DEV }}" | base64 -d > kubeconfig
        export KUBECONFIG=kubeconfig

    - name: Deploy to development
      run: |
        export KUBECONFIG=kubeconfig
        kubectl apply -k k8s/overlays/development
        kubectl rollout status deployment/dev-pynode -n ${{ env.K8S_NAMESPACE }}
        kubectl rollout status deployment/dev-pynode-frontend -n ${{ env.K8S_NAMESPACE }}

    - name: Run smoke tests
      run: |
        export KUBECONFIG=kubeconfig
        kubectl wait --for=condition=ready pod -l app=dev-pynode -n ${{ env.K8S_NAMESPACE }} --timeout=300s
        # Add actual smoke tests here

  deploy-prod:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main' || github.event_name == 'release'
    environment: production

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'

    - name: Configure kubectl
      run: |
        echo "${{ secrets.KUBE_CONFIG_PROD }}" | base64 -d > kubeconfig
        export KUBECONFIG=kubeconfig

    - name: Deploy to production
      run: |
        export KUBECONFIG=kubeconfig
        kubectl apply -k k8s/overlays/production
        kubectl rollout status deployment/dev-pynode -n ${{ env.K8S_NAMESPACE }}
        kubectl rollout status deployment/dev-pynode-frontend -n ${{ env.K8S_NAMESPACE }}

    - name: Run health checks
      run: |
        export KUBECONFIG=kubeconfig
        kubectl wait --for=condition=ready pod -l app=dev-pynode -n ${{ env.K8S_NAMESPACE }} --timeout=300s
        # Add actual health checks here

    - name: Notify deployment
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        channel: '#deployments'
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
      if: always()
```

## Security Scanning

### Vulnerability Scanning

```yaml
  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: build
    if: github.event_name == 'push'

    steps:
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ needs.build.outputs.image-tag }}
        format: 'sarif'
        output: 'trivy-results.sarif'

    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
```

### Dependency Scanning

```yaml
  dependency-scan:
    name: Dependency Scan
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Run Snyk to check for vulnerabilities
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        args: --severity-threshold=high

    - name: Run Snyk to check for vulnerabilities (Python)
      uses: snyk/actions/python@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        args: --severity-threshold=high
```

## Performance Testing

### Load Testing

```yaml
  performance-test:
    name: Performance Test
    runs-on: ubuntu-latest
    needs: deploy-dev
    if: github.ref == 'refs/heads/develop'

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Run Lighthouse CI
      run: |
        npm install -g @lhci/cli@0.12.x
        lhci autorun

    - name: Upload Lighthouse results
      uses: actions/upload-artifact@v3
      with:
        name: lighthouse-results
        path: .lighthouseci/
```

### Load Testing with Artillery

```yaml
  load-test:
    name: Load Test
    runs-on: ubuntu-latest
    needs: deploy-dev
    if: github.ref == 'refs/heads/develop'

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'

    - name: Install Artillery
      run: npm install -g artillery

    - name: Run load test
      run: artillery run load-test.yml
      env:
        TARGET_URL: https://dev-api.dev-pynode.com
```

## GitOps with ArgoCD

### ArgoCD Application

```yaml
# argocd/application.yaml
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
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
```

### ArgoCD Sync

```yaml
  argocd-sync:
    name: ArgoCD Sync
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Update ArgoCD
      run: |
        # Update image tag in k8s manifests
        sed -i "s|image: bionic-ai-solutions/dev-pynode:.*|image: bionic-ai-solutions/dev-pynode:${{ needs.build.outputs.image-tag }}|g" k8s/overlays/production/kustomization.yaml
        
        # Commit and push changes
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add k8s/overlays/production/kustomization.yaml
        git commit -m "Update image tag to ${{ needs.build.outputs.image-tag }}"
        git push

    - name: Trigger ArgoCD sync
      run: |
        curl -X POST \
          -H "Authorization: Bearer ${{ secrets.ARGOCD_TOKEN }}" \
          -H "Content-Type: application/json" \
          -d '{"revision": "HEAD"}' \
          https://argocd.dev-pynode.com/api/v1/applications/dev-pynode/sync
```

## Environment Management

### Environment Configuration

```yaml
# Environment-specific configurations
environments:
  development:
    url: https://dev-api.dev-pynode.com
    kubeconfig: ${{ secrets.KUBE_CONFIG_DEV }}
    namespace: dev-pynode
    replicas: 1
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"
        cpu: "500m"

  staging:
    url: https://staging-api.dev-pynode.com
    kubeconfig: ${{ secrets.KUBE_CONFIG_STAGING }}
    namespace: dev-pynode-staging
    replicas: 2
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "1000m"

  production:
    url: https://api.dev-pynode.com
    kubeconfig: ${{ secrets.KUBE_CONFIG_PROD }}
    namespace: dev-pynode
    replicas: 3
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "2000m"
```

### Feature Flags

```yaml
  feature-flags:
    name: Update Feature Flags
    runs-on: ubuntu-latest
    steps:
    - name: Update feature flags
      run: |
        # Update feature flags based on environment
        if [ "${{ github.ref }}" == "refs/heads/main" ]; then
          echo "FEATURE_NEW_UI=true" >> .env.production
          echo "FEATURE_BETA_FEATURES=false" >> .env.production
        else
          echo "FEATURE_NEW_UI=true" >> .env.development
          echo "FEATURE_BETA_FEATURES=true" >> .env.development
        fi
```

## Rollback Strategy

### Automated Rollback

```yaml
  rollback:
    name: Rollback
    runs-on: ubuntu-latest
    if: failure()
    needs: [deploy-prod]

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'

    - name: Configure kubectl
      run: |
        echo "${{ secrets.KUBE_CONFIG_PROD }}" | base64 -d > kubeconfig
        export KUBECONFIG=kubeconfig

    - name: Rollback deployment
      run: |
        export KUBECONFIG=kubeconfig
        kubectl rollout undo deployment/dev-pynode -n ${{ env.K8S_NAMESPACE }}
        kubectl rollout status deployment/dev-pynode -n ${{ env.K8S_NAMESPACE }}

    - name: Notify rollback
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        channel: '#alerts'
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Manual Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/dev-pynode -n dev-pynode

# Rollback to specific revision
kubectl rollout undo deployment/dev-pynode --to-revision=2 -n dev-pynode

# Check rollout history
kubectl rollout history deployment/dev-pynode -n dev-pynode
```

## Monitoring and Alerting

### Deployment Monitoring

```yaml
  monitor-deployment:
    name: Monitor Deployment
    runs-on: ubuntu-latest
    needs: deploy-prod
    if: always()

    steps:
    - name: Check deployment health
      run: |
        # Wait for deployment to be ready
        kubectl wait --for=condition=ready pod -l app=dev-pynode -n dev-pynode --timeout=300s
        
        # Run health checks
        curl -f https://api.dev-pynode.com/health
        
        # Check metrics
        curl -f https://api.dev-pynode.com/metrics

    - name: Send deployment notification
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        channel: '#deployments'
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Best Practices

### 1. Pipeline Design

**Principles**:
- Fast feedback loops
- Fail fast on critical issues
- Parallel execution where possible
- Clear separation of concerns

### 2. Security

**Measures**:
- Use secrets for sensitive data
- Sign Docker images
- Scan for vulnerabilities
- Use least privilege access

### 3. Testing

**Strategy**:
- Unit tests for all new code
- Integration tests for critical paths
- End-to-end tests for user journeys
- Performance tests for scalability

### 4. Deployment

**Approaches**:
- Blue-green deployments
- Canary releases
- Feature flags
- Automated rollbacks

## Troubleshooting

### Common Issues

1. **Build Failures**
   ```bash
   # Check build logs
   docker build --no-cache -t dev-pynode .
   
   # Check Dockerfile syntax
   docker run --rm -i hadolint/hadolint < Dockerfile
   ```

2. **Test Failures**
   ```bash
   # Run tests locally
   npm test
   pytest tests/
   
   # Check test coverage
   npm run test:coverage
   ```

3. **Deployment Issues**
   ```bash
   # Check Kubernetes resources
   kubectl get pods -n dev-pynode
   kubectl describe pod <pod-name> -n dev-pynode
   
   # Check logs
   kubectl logs -f deployment/dev-pynode -n dev-pynode
   ```

### Debugging

```yaml
  debug:
    name: Debug
    runs-on: ubuntu-latest
    if: failure()
    steps:
    - name: Debug information
      run: |
        echo "GitHub Event: ${{ github.event_name }}"
        echo "Branch: ${{ github.ref }}"
        echo "Commit: ${{ github.sha }}"
        echo "Actor: ${{ github.actor }}"
```

## Next Steps

- [Deployment Guide](deployment.md) - Production deployment
- [Monitoring Guide](monitoring.md) - System monitoring
- [Troubleshooting Guide](troubleshooting.md) - Common issues
- [Architecture Documentation](architecture.md) - System design
