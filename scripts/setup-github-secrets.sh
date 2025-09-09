#!/bin/bash

# =============================================================================
# GitHub Secrets Setup Helper Script
# =============================================================================
# This script helps set up GitHub secrets for CI/CD pipeline
# Usage: ./scripts/setup-github-secrets.sh <project-name>

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

PROJECT_NAME=""
GITHUB_ORG="Bionic-AI-Solutions"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 -n <project-name>"
            echo
            echo "Options:"
            echo "  -n, --name    Project name (kebab-case)"
            echo "  -h, --help    Show this help message"
            echo
            echo "Example:"
            echo "  $0 -n my-awesome-project"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$PROJECT_NAME" ]; then
    log_error "Project name is required"
    echo "Usage: $0 -n <project-name>"
    exit 1
fi

echo "=========================================="
echo "  GitHub Secrets Setup Helper"
echo "=========================================="
echo

log_info "Setting up GitHub secrets for project: $PROJECT_NAME"
echo

# Check if GitHub CLI is available
if ! command -v gh &> /dev/null; then
    log_warning "GitHub CLI not found. Please install it first:"
    echo "  https://cli.github.com/"
    echo
    log_info "Manual setup instructions:"
    echo "1. Go to: https://github.com/$GITHUB_ORG/$PROJECT_NAME/settings/secrets/actions"
    echo "2. Add the following secrets manually:"
    echo
    exit 1
fi

# Check if user is logged in to GitHub CLI
if ! gh auth status &> /dev/null; then
    log_error "Not logged in to GitHub CLI"
    log_info "Please run: gh auth login"
    exit 1
fi

log_info "Collecting secrets..."

# Get Docker Hub username
echo
log_info "Docker Hub Setup:"
echo "1. Go to: https://hub.docker.com/settings/security"
echo "2. Create a new access token with 'Read, Write, Delete' permissions"
echo
read -p "Enter your Docker Hub username: " DOCKERHUB_USERNAME
read -s -p "Enter your Docker Hub access token: " DOCKERHUB_TOKEN
echo

# Get ArgoCD password
echo
log_info "ArgoCD Setup:"
echo "Get the ArgoCD admin password by running:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo
read -s -p "Enter ArgoCD admin password: " ARGOCD_PASSWORD
echo

# Set GitHub secrets
log_info "Setting GitHub secrets..."

# Set DOCKERHUB_USERNAME
if gh secret set DOCKERHUB_USERNAME --body "$DOCKERHUB_USERNAME" --repo "$GITHUB_ORG/$PROJECT_NAME"; then
    log_success "DOCKERHUB_USERNAME secret set"
else
    log_error "Failed to set DOCKERHUB_USERNAME secret"
fi

# Set DOCKERHUB_TOKEN
if gh secret set DOCKERHUB_TOKEN --body "$DOCKERHUB_TOKEN" --repo "$GITHUB_ORG/$PROJECT_NAME"; then
    log_success "DOCKERHUB_TOKEN secret set"
else
    log_error "Failed to set DOCKERHUB_TOKEN secret"
fi

# Set ARGOCD_PASSWORD
if gh secret set ARGOCD_PASSWORD --body "$ARGOCD_PASSWORD" --repo "$GITHUB_ORG/$PROJECT_NAME"; then
    log_success "ARGOCD_PASSWORD secret set"
else
    log_error "Failed to set ARGOCD_PASSWORD secret"
fi

echo
log_success "GitHub secrets setup completed!"
echo
echo "You can verify the secrets are set by running:"
echo "gh secret list --repo $GITHUB_ORG/$PROJECT_NAME"
echo
echo "Next steps:"
echo "1. Push a commit to trigger the CI/CD pipeline"
echo "2. Monitor the build at: https://github.com/$GITHUB_ORG/$PROJECT_NAME/actions"
echo "3. Check ArgoCD deployment at: https://argocd.bionicaisolutions.com"
