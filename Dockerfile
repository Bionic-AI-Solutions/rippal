# =============================================================================
# Dev-Container Template
# A development environment with Node.js, Python, and Kubernetes tools
# =============================================================================

FROM node:18-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    postgresql-client \
    curl \
    git \
    openssh-server \
    kubectl \
    helm \
    k9s \
    && rm -rf /var/cache/apk/*

# Create working directory
WORKDIR /app

# =============================================================================
# Development Stage
# =============================================================================
FROM base AS development

# Install Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python development tools
RUN pip install --no-cache-dir \
    fastapi \
    uvicorn \
    pydantic \
    sqlalchemy \
    psycopg2-binary \
    redis \
    python-dotenv \
    pytest \
    black \
    flake8 \
    isort

# Install Node.js development tools
RUN npm install -g \
    typescript \
    ts-node \
    nodemon \
    eslint \
    prettier \
    concurrently

# Create SSH configuration
RUN mkdir -p /var/run/sshd && \
    adduser -D -s /bin/bash developer && \
    echo 'root:dev123' | chpasswd && \
    echo 'developer:dev123' | chpasswd && \
    echo 'developer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Configure SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Generate SSH host keys
RUN ssh-keygen -A

# Create startup script
RUN echo '#!/bin/sh' > /startup.sh && \
    echo '/usr/sbin/sshd -D &' >> /startup.sh && \
    echo 'exec "$@"' >> /startup.sh && \
    chmod +x /startup.sh

# Expose SSH port
EXPOSE 22

# Set startup command
CMD ["/startup.sh", "tail", "-f", "/dev/null"]

# =============================================================================
# Frontend Build Stage
# =============================================================================
FROM base AS frontend-build

# Install Node.js development tools
RUN npm install -g \
    typescript \
    ts-node \
    nodemon \
    eslint \
    prettier \
    concurrently

# Create SSH configuration
RUN mkdir -p /var/run/sshd && \
    adduser -D -s /bin/bash developer && \
    echo 'root:dev123' | chpasswd && \
    echo 'developer:dev123' | chpasswd && \
    echo 'developer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Configure SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Generate SSH host keys
RUN ssh-keygen -A

# Create startup script
RUN echo '#!/bin/sh' > /startup.sh && \
    echo '/usr/sbin/sshd -D &' >> /startup.sh && \
    echo 'exec "$@"' >> /startup.sh && \
    chmod +x /startup.sh

# Expose ports
EXPOSE 22 80

# Set startup command
CMD ["/startup.sh", "tail", "-f", "/dev/null"]

# =============================================================================
# Production Stage (for CI/CD)
# =============================================================================
FROM base AS production

# Install Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python development tools
RUN pip install --no-cache-dir \
    fastapi \
    uvicorn \
    pydantic \
    sqlalchemy \
    psycopg2-binary \
    redis \
    python-dotenv

# Install Node.js development tools
RUN npm install -g \
    typescript \
    ts-node \
    nodemon \
    eslint \
    prettier \
    concurrently

# Create SSH configuration
RUN mkdir -p /var/run/sshd && \
    adduser -D -s /bin/bash developer && \
    echo 'root:dev123' | chpasswd && \
    echo 'developer:dev123' | chpasswd && \
    echo 'developer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Configure SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Generate SSH host keys
RUN ssh-keygen -A

# Create startup script
RUN echo '#!/bin/sh' > /startup.sh && \
    echo '/usr/sbin/sshd -D &' >> /startup.sh && \
    echo 'tail -f /dev/null' >> /startup.sh && \
    chmod +x /startup.sh

# Expose ports
EXPOSE 22 3000 8000

# Set startup command
CMD ["/startup.sh"]