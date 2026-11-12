#!/bin/bash

KIND="/mnt/c/Users/o_dar/AppData/Local/Microsoft/WinGet/Links/kind.exe"
HELM="/mnt/c/Users/o_dar/AppData/Local/Microsoft/WinGet/Links/helm.exe"

set -e

# Check prerequisites
for tool in docker kubectl; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed"
        exit 1
    fi
done

if [[ ! -f "$KIND" || ! -f "$HELM" ]]; then
    echo "Error: kind.exe or helm.exe not found"
    exit 1
fi

# Check Docker
docker info > /dev/null

# Create kind cluster if it does not exist
if ! "$KIND" get clusters | grep -q "^todoapp$"; then
    "$KIND" create cluster --name todoapp --config cluster.yml
fi

# Install Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Update Helm dependencies
"$HELM" dependency update ./helm-chart/todoapp

# Deploy application using Helm
"$HELM" upgrade --install todoapp ./helm-chart/todoapp \
    --take-ownership \
    --wait \
    --timeout 10m

echo "Deployment completed successfully!"