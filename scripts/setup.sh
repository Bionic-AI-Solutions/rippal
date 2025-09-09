#!/bin/bash

# =============================================================================
# Dev-PyNode Setup Script
# =============================================================================
# This script sets up the development environment for Dev-PyNode

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Setup Functions
# =============================================================================

setup_environment() {
    log_info "Setting up environment..."
    
    if [ ! -f ".env" ]; then
        cp .env.example .env
        log_success "Environment file created from .env.example"
    else
        log_warning ".env file already exists, skipping..."
    fi
}

setup_directories() {
    log_info "Creating necessary directories..."
    
    mkdir -p logs
    mkdir -p uploads
    mkdir -p data
    mkdir -p /opt/ai-models
    
    log_success "Directories created"
}

setup_database() {
    log_info "Setting up database..."
    
    # Wait for PostgreSQL to be ready
    log_info "Waiting for PostgreSQL to be ready..."
    until docker-compose exec -T postgres pg_isready -U postgres; do
        sleep 2
    done
    
    # Run migrations if they exist
    if [ -f "scripts/migrate.js" ]; then
        npm run db:migrate
    fi
    
    # Seed database if seed script exists
    if [ -f "scripts/seed.js" ]; then
        npm run db:seed
    fi
    
    log_success "Database setup completed"
}

setup_ai_models() {
    log_info "Setting up AI models..."
    
    # Download default models if script exists
    if [ -f "scripts/download.py" ]; then
        python3 scripts/download.py
    fi
    
    log_success "AI models setup completed"
}

install_dependencies() {
    log_info "Installing dependencies..."
    
    # Install Node.js dependencies
    if [ -f "package.json" ]; then
        npm install
        log_success "Node.js dependencies installed"
    fi
    
    # Install Python dependencies
    if [ -f "requirements.txt" ]; then
        pip3 install -r requirements.txt
        log_success "Python dependencies installed"
    fi
    
    # Install development dependencies
    if [ -f "requirements-dev.txt" ]; then
        pip3 install -r requirements-dev.txt
        log_success "Python development dependencies installed"
    fi
}

setup_git_hooks() {
    log_info "Setting up Git hooks..."
    
    if [ -f "package.json" ] && grep -q "husky" package.json; then
        npm run prepare
        log_success "Git hooks installed"
    else
        log_warning "Husky not found in package.json, skipping Git hooks setup"
    fi
}

start_services() {
    log_info "Starting services..."
    
    # Start Docker services
    docker-compose up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 10
    
    # Check service health
    check_service_health
    
    log_success "Services started successfully"
}

check_service_health() {
    log_info "Checking service health..."
    
    # Check PostgreSQL
    if docker-compose exec -T postgres pg_isready -U postgres; then
        log_success "PostgreSQL is healthy"
    else
        log_error "PostgreSQL is not healthy"
        exit 1
    fi
    
    # Check Redis
    if docker-compose exec -T redis redis-cli ping | grep -q PONG; then
        log_success "Redis is healthy"
    else
        log_error "Redis is not healthy"
        exit 1
    fi
    
    # Check MinIO
    if curl -f http://localhost:9000/minio/health/live > /dev/null 2>&1; then
        log_success "MinIO is healthy"
    else
        log_warning "MinIO health check failed, but continuing..."
    fi
}

run_tests() {
    log_info "Running tests..."
    
    # Run unit tests
    if [ -f "package.json" ] && grep -q "test:unit" package.json; then
        npm run test:unit || log_warning "Unit tests failed"
    fi
    
    # Run Python tests
    if [ -f "requirements-dev.txt" ] && grep -q "pytest" requirements-dev.txt; then
        pytest tests/unit/ -v || log_warning "Python unit tests failed"
    fi
    
    log_success "Tests completed"
}

show_status() {
    log_success "Setup completed successfully!"
    echo
    echo "Service Status:"
    echo "==============="
    docker-compose ps
    echo
    echo "Access URLs:"
    echo "============"
    echo "Frontend: http://localhost:3001"
    echo "Backend API: http://localhost:3000"
    echo "API Documentation: http://localhost:3000/docs"
    echo "pgAdmin: http://localhost:5050"
    echo "Redis Commander: http://localhost:8081"
    echo "MinIO Console: http://localhost:9001"
    echo "Grafana: http://localhost:3001 (admin/admin123)"
    echo
    echo "Useful Commands:"
    echo "================"
    echo "View logs: docker-compose logs -f"
    echo "Stop services: docker-compose down"
    echo "Restart services: docker-compose restart"
    echo "Run tests: npm test"
    echo "Deploy to K8s: kubectl apply -k k8s/overlays/development"
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "=========================================="
    echo "  Dev-PyNode Setup Script"
    echo "=========================================="
    echo
    
    setup_environment
    setup_directories
    install_dependencies
    setup_git_hooks
    start_services
    setup_database
    setup_ai_models
    run_tests
    show_status
}

# Run main function
main "$@"

