# Dev-Template

A comprehensive development environment template with Node.js, Python, and Kubernetes tools ready for use.

## 🚀 Features

- **Node.js 18+** with TypeScript, ESLint, Prettier
- **Python 3.11+** with FastAPI, SQLAlchemy, pytest
- **Kubernetes Tools**: kubectl, Helm, k9s
- **SSH Server** for remote access
- **Docker & Docker Compose** for containerization
- **CI/CD Pipeline** with GitHub Actions
- **Kubernetes Deployment** with ArgoCD integration

## 📋 Prerequisites

- Docker and Docker Compose
- Git
- Kubernetes cluster (for deployment)

## 🛠️ Quick Start

### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Bionic-AI-Solutions/rippal.git
   cd rippal
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start development environment**
   ```bash
   docker-compose up -d
   ```

4. **Access the development container**
   ```bash
   # SSH access
   ssh developer@localhost -p 2222
   # Password: dev123
   
   # Or direct Docker exec
   docker exec -it rippal bash
   ```

## 🔧 Available Tools

### Node.js Development
- **Node.js 18+** with npm
- **TypeScript** for type-safe JavaScript
- **ESLint** for code linting
- **Prettier** for code formatting
- **nodemon** for development

### Python Development
- **Python 3.11+** with pip
- **FastAPI** for web APIs
- **SQLAlchemy** for database ORM
- **pytest** for testing
- **Black, Flake8, isort** for code quality

### Kubernetes Tools
- **kubectl** for cluster management
- **Helm** for package management
- **k9s** for cluster monitoring

### Databases & Services
- **PostgreSQL** (port 5433)
- **Redis** (port 6380)
- **MinIO** (port 9000)
- **Prometheus** (port 9090)
- **Grafana** (port 3003)

## 📁 Project Structure

```
rippal/
├── .github/workflows/     # CI/CD pipeline
├── k8s/                   # Kubernetes manifests
├── docker/                # Docker configurations
├── docs/                  # Documentation
├── scripts/               # Helper scripts
├── docker-compose.yml     # Local development
├── Dockerfile            # Container definition
└── README.md             # This file
```

## 🚀 Deployment

### Local Development
```bash
docker-compose up -d
```

### Kubernetes Deployment
```bash
# Deploy to development
kubectl apply -k k8s/overlays/development

# Deploy to production
kubectl apply -k k8s/overlays/production
```

### CI/CD Pipeline
The GitHub Actions workflow automatically:
1. Builds Docker image
2. Pushes to Docker Hub
3. Triggers ArgoCD sync for deployment

**Required GitHub Secrets:**
- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_TOKEN`: Your Docker Hub access token
- `ARGOCD_PASSWORD`: ArgoCD admin password for argocd.bionicaisolutions.com

**Required Kubernetes Setup:**
- Docker registry secret for pulling images from Docker Hub
- Use the provided script: `./scripts/create-docker-secret.sh <username> <token>`

## 🔐 Access Information

#### SSH Access
- **Host**: localhost
- **Port**: 2222
- **User**: developer
- **Password**: dev123

#### Application Ports
- **SSH**: Port 22 (for remote development access)
- **Frontend**: Port 3000 (React/Node.js frontend)
- **FastAPI**: Port 8000 (Python backend API)
- **PostgreSQL**: 5433
- **Redis**: 6380
- **MinIO**: 9000
- **Grafana**: 3003
- **Prometheus**: 9090

## 📚 Documentation

- [Installation Guide](docs/installation.md)
- [Configuration](docs/configuration.md)
- [Development Guide](docs/development.md)
- [Docker Deployment](docs/docker-deployment.md)
- [Kubernetes Deployment](docs/kubernetes-deployment.md)
- [CI/CD Pipeline](docs/cicd-pipeline.md)
- [Monitoring](docs/monitoring.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in this repository
- Check the [troubleshooting guide](docs/troubleshooting.md)
- Review the [documentation](docs/)

---

**Ready to start developing?** Run `docker-compose up -d` and SSH into your development environment!# Trigger ArgoCD test
