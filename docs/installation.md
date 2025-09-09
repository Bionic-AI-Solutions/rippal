# Installation Guide

This guide will walk you through installing and setting up Dev-PyNode on your system.

## Prerequisites

Before installing Dev-PyNode, ensure you have the following prerequisites installed:

### Required Software

- **Docker** (version 20.10+)
- **Docker Compose** (version 2.0+)
- **Node.js** (version 18+)
- **Python** (version 3.11+)
- **Git** (version 2.30+)

### Optional Software

- **Kubernetes** (version 1.28+) - for production deployment
- **kubectl** - for Kubernetes management
- **Helm** (version 3.0+) - for package management

## Installation Methods

### Method 1: Quick Setup (Recommended)

1. **Clone the repository**
   ```bash
   git clone https://github.com/Bionic-AI-Solutions/dev-pynode.git
   cd dev-pynode
   ```

2. **Run the bootstrap script**
   ```bash
   ./bootstrap.sh -n my-project -s fullstack -d "My awesome project"
   ```

3. **Start the development environment**
   ```bash
   ./scripts/setup.sh
   ```

### Method 2: Manual Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Bionic-AI-Solutions/dev-pynode.git
   cd dev-pynode
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Install dependencies**
   ```bash
   # Node.js dependencies
   npm install
   
   # Python dependencies
   pip3 install -r requirements.txt
   pip3 install -r requirements-dev.txt
   ```

4. **Start services**
   ```bash
   docker-compose up -d
   ```

## Platform-Specific Instructions

### Ubuntu/Debian

```bash
# Update package list
sudo apt update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs

# Install Python
sudo apt install python3 python3-pip python3-venv

# Install Git
sudo apt install git
```

### macOS

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker

# Install Node.js
brew install node

# Install Python
brew install python@3.11

# Install Git
brew install git
```

### Windows

1. **Install Docker Desktop**
   - Download from [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
   - Follow the installation wizard

2. **Install Node.js**
   - Download from [Node.js official website](https://nodejs.org/)
   - Choose the LTS version

3. **Install Python**
   - Download from [Python official website](https://www.python.org/downloads/)
   - Choose Python 3.11+

4. **Install Git**
   - Download from [Git for Windows](https://git-scm.com/download/win)

## Verification

After installation, verify that everything is working correctly:

```bash
# Check Docker
docker --version
docker-compose --version

# Check Node.js
node --version
npm --version

# Check Python
python3 --version
pip3 --version

# Check Git
git --version
```

## Troubleshooting

### Common Issues

1. **Docker permission denied**
   ```bash
   sudo usermod -aG docker $USER
   # Log out and log back in
   ```

2. **Port conflicts**
   - Check if ports 3000, 3001, 5432, 6379, 9000 are available
   - Modify ports in `docker-compose.yml` if needed

3. **Python package installation fails**
   ```bash
   # Use virtual environment
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

4. **Node.js version issues**
   ```bash
   # Use nvm to manage Node.js versions
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   nvm install 18
   nvm use 18
   ```

### Getting Help

If you encounter issues:

1. Check the [Troubleshooting Guide](troubleshooting.md)
2. Search [GitHub Issues](https://github.com/Bionic-AI-Solutions/dev-pynode/issues)
3. Join our [Discussions](https://github.com/Bionic-AI-Solutions/dev-pynode/discussions)

## Next Steps

After successful installation:

1. Read the [Quick Start Guide](quick-start.md)
2. Configure your environment in [Configuration Guide](configuration.md)
3. Explore the [API Reference](api-reference.md)

## Uninstallation

To remove Dev-PyNode:

```bash
# Stop and remove containers
docker-compose down -v

# Remove images
docker rmi dev-pynode

# Remove volumes
docker volume prune

# Remove the project directory
rm -rf dev-pynode
```
