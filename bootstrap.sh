
#!/bin/bash
set -e

KIND_BIN="${KIND_BIN:-kind}"
HELM_BIN="${HELM_BIN:-helm}"
KUBECTL_BIN="${KUBECTL_BIN:-kubectl}"
CONTEXT="kind-todoapp"
CHART=".infrastructure/helm-chart/todoapp"

# Check prerequisites
for tool in docker "$KIND_BIN" "$HELM_BIN" "$KUBECTL_BIN"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: $tool is not installed or not found in PATH"
        exit 1
    fi
done

# Check Docker
docker info >/dev/null

# Create kind cluster if it does not exist
if ! "$KIND_BIN" get clusters | grep -qx "todoapp"; then
    "$KIND_BIN" create cluster --name todoapp --config cluster.yml
fi

# Wait for nodes
"$KUBECTL_BIN" --context "$CONTEXT" wait \
    --for=condition=Ready nodes --all --timeout=180s

# Inspect node labels and taints
"$KUBECTL_BIN" --context "$CONTEXT" get nodes \
    -o custom-columns=NAME:.metadata.name,APP:.metadata.labels.app,TAINTS:.spec.taints

# Apply MySQL node taints
"$KUBECTL_BIN" --context "$CONTEXT" taint nodes \
    -l app=mysql app=mysql:NoSchedule --overwrite

# Install Ingress Controller
"$KUBECTL_BIN" --context "$CONTEXT" apply \
    -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

"$KUBECTL_BIN" --context "$CONTEXT" wait \
    --namespace ingress-nginx \
    --for=condition=Ready pods \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s

# Update Helm dependencies
"$HELM_BIN" dependency update "$CHART"

# Deploy application using Helm
"$HELM_BIN" upgrade --install todoapp "$CHART" \
    --kube-context "$CONTEXT" \
    --take-ownership \
    --wait \
    --timeout 10m

echo "Deployment completed successfully!"
