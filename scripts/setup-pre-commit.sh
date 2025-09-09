#!/bin/bash

# Setup Pre-commit Hooks for Dev-PyNode Project
# This script installs and configures pre-commit hooks for automated testing

set -e

echo "🚀 Setting up pre-commit hooks for Dev-PyNode project..."

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "📦 Installing pre-commit..."
    pip install pre-commit
else
    echo "✅ pre-commit is already installed"
fi

# Install the pre-commit hooks
echo "🔧 Installing pre-commit hooks..."
pre-commit install

# Test the hooks
echo "🧪 Testing pre-commit hooks..."
pre-commit run --all-files

echo "✅ Pre-commit hooks setup complete!"
echo ""
echo "📋 What this setup provides:"
echo "  • Automatic Docker build testing before commits"
echo "  • Frontend linting (ESLint) before commits"
echo "  • Backend linting (flake8, black, isort) before commits"
echo "  • Frontend tests before commits"
echo "  • Backend tests before commits"
echo "  • Code quality checks (trailing whitespace, etc.)"
echo ""
echo "💡 Usage:"
echo "  • Hooks run automatically on 'git commit'"
echo "  • Run manually: pre-commit run --all-files"
echo "  • Skip hooks: git commit --no-verify"
echo "  • Update hooks: pre-commit autoupdate"
echo ""
echo "🎯 This ensures all code quality checks pass before commits!"
