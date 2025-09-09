#!/bin/bash

# Script to create Docker registry secret for Kubernetes
# Usage: ./scripts/create-docker-secret.sh <dockerhub-username> <dockerhub-token>

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <dockerhub-username> <dockerhub-token>"
    echo "Example: $0 docker4zerocool your-dockerhub-token"
    exit 1
fi

DOCKERHUB_USERNAME=$1
DOCKERHUB_TOKEN=$2
NAMESPACE="dev-template"
SECRET_NAME="docker-registry-secret"

echo "Creating Docker registry secret for namespace: $NAMESPACE"

# Create the base64 encoded docker config
DOCKER_CONFIG=$(echo "{\"auths\":{\"https://index.docker.io/v1/\":{\"username\":\"$DOCKERHUB_USERNAME\",\"password\":\"$DOCKERHUB_TOKEN\",\"email\":\"$DOCKERHUB_USERNAME@example.com\",\"auth\":\"$(echo -n "$DOCKERHUB_USERNAME:$DOCKERHUB_TOKEN" | base64 -w 0)\"}}}" | base64 -w 0)

# Update the secret.yaml file
cat > k8s/base/secret.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: docker-registry-secret
  namespace: dev-template
  labels:
    app: dev-template
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: $DOCKER_CONFIG
EOF

echo "Docker registry secret updated in k8s/base/secret.yaml"
echo "The secret now contains the actual Docker Hub credentials"
echo ""
echo "You can now commit and push this change:"
echo "git add k8s/base/secret.yaml"
echo "git commit -m 'Update Docker registry secret with real credentials'"
echo "git push origin main"
echo ""
echo "ArgoCD will automatically sync the updated secret"
