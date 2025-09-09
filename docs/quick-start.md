# Quick Start Guide

Get up and running with Dev-PyNode in minutes!

## 🚀 5-Minute Setup

### Step 1: Clone and Bootstrap

```bash
git clone https://github.com/Bionic-AI-Solutions/dev-pynode.git
cd dev-pynode
./bootstrap.sh -n my-awesome-project -s fullstack -d "My awesome AI project"
```

### Step 2: Start Services

```bash
./scripts/setup.sh
```

### Step 3: Access Your Application

- **Frontend**: http://localhost:3001
- **Backend API**: http://localhost:3000
- **API Documentation**: http://localhost:3000/docs

## 🎯 First Steps

### 1. Verify Installation

Check that all services are running:

```bash
docker-compose ps
```

You should see all services in "Up" status.

### 2. Test the API

```bash
# Health check
curl http://localhost:3000/health

# Expected response:
# {"status": "healthy"}
```

### 3. Explore the API Documentation

Visit http://localhost:3000/docs to see the interactive API documentation.

## 🛠️ Development Workflow

### Starting Development

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Making Changes

1. **Backend Changes**: Edit files in `backend/` or `src/`
2. **Frontend Changes**: Edit files in `frontend/`
3. **Configuration**: Update `.env` file
4. **Dependencies**: Update `package.json` or `requirements.txt`

### Running Tests

```bash
# All tests
npm test

# Unit tests only
npm run test:unit

# Integration tests
npm run test:integration

# Python tests
pytest tests/unit/
```

## 🔧 Common Tasks

### Database Operations

```bash
# Run migrations
npm run db:migrate

# Seed database
npm run db:seed

# Access database
docker-compose exec postgres psql -U postgres -d dev_template_db
```

### AI Model Management

```bash
# Download models
python3 scripts/download.py

# List available models
docker-compose exec ollama ollama list

# Pull a new model
docker-compose exec ollama ollama pull llama2
```

### Monitoring

```bash
# View application logs
docker-compose logs -f backend

# Check service health
curl http://localhost:3000/health

# Access Grafana
open http://localhost:3001
# Login: admin/admin123
```

## 📊 Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Frontend | http://localhost:3001 | - |
| Backend API | http://localhost:3000 | - |
| API Docs | http://localhost:3000/docs | - |
| pgAdmin | http://localhost:5050 | admin@dev-pynode.com / admin123 |
| Redis Commander | http://localhost:8081 | admin / admin123 |
| MinIO Console | http://localhost:9001 | minioadmin / minioadmin123 |
| Grafana | http://localhost:3001 | admin / admin123 |

## 🚀 Deployment

### Local Kubernetes

```bash
# Deploy to local K8s
kubectl apply -k k8s/overlays/development

# Check deployment
kubectl get pods -n dev-pynode

# Access services
kubectl port-forward svc/dev-pynode-service 3000:3000 -n dev-pynode
```

### Production Deployment

```bash
# Deploy to production
kubectl apply -k k8s/overlays/production

# Monitor deployment
kubectl rollout status deployment/dev-pynode -n dev-pynode
```

## 🔍 Troubleshooting

### Services Not Starting

```bash
# Check Docker status
docker ps

# Check logs
docker-compose logs

# Restart services
docker-compose restart
```

### Port Conflicts

If you get port conflicts, modify `docker-compose.yml`:

```yaml
services:
  backend:
    ports:
      - "3001:3000"  # Change 3000 to 3001
```

### Database Connection Issues

```bash
# Check PostgreSQL
docker-compose exec postgres pg_isready -U postgres

# Reset database
docker-compose down -v
docker-compose up -d
```

## 📚 Next Steps

1. **Read the [Configuration Guide](configuration.md)** to customize your setup
2. **Explore the [API Reference](api-reference.md)** to understand the API
3. **Check the [Architecture Documentation](architecture.md)** to understand the system
4. **Follow the [Development Guide](development.md)** for advanced development

## 🆘 Need Help?

- **Documentation**: Check other guides in the `docs/` folder
- **Issues**: [GitHub Issues](https://github.com/Bionic-AI-Solutions/dev-pynode/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Bionic-AI-Solutions/dev-pynode/discussions)
- **Community**: Join our Discord server

## 🎉 Congratulations!

You now have a fully functional AI-powered development platform running locally! 

Try making your first API call:

```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, AI!"}'
```
