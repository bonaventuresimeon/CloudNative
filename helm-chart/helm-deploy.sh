#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="student-tracker"
KIND_CONFIG="k8s/kind-config.yaml"
RELEASE_NAME="student-tracker"
NAMESPACE="student-tracker"
INGRESS_NAMESPACE="ingress-nginx"
CHART_PATH="helm/student-tracker"
EC2_DNS="ec2-54-170-56-216.eu-west-1.compute.amazonaws.com"
INGRESS_MANIFEST="https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml"

log() {
  echo "[$(date --iso-8601=seconds)] $*"
}

# 1. Create cluster if missing
if ! kind get clusters | grep -q "^$CLUSTER_NAME$"; then
  log "Creating Kind cluster..."
  kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
else
  log "Kind cluster '$CLUSTER_NAME' already exists."
fi

kubectl config use-context "kind-$CLUSTER_NAME"

# 2. Create namespaces
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"
kubectl get ns "$INGRESS_NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$INGRESS_NAMESPACE"

# 3. Install Ingress Controller
if ! kubectl get deployment ingress-nginx-controller -n "$INGRESS_NAMESPACE" >/dev/null 2>&1; then
  log "Installing ingress-nginx..."
  kubectl apply --validate=false -f "$INGRESS_MANIFEST"
  kubectl rollout status deployment/ingress-nginx-controller -n "$INGRESS_NAMESPACE"
fi

# Patch Ingress to LoadBalancer
kubectl patch svc ingress-nginx-controller -n "$INGRESS_NAMESPACE" --type='merge' \
  -p '{"spec":{"type":"LoadBalancer"}}' || true

# 4. Helm install
log "Deploying Helm chart..."
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" -n "$NAMESPACE" --create-namespace

# 5. Status check
log "Waiting for rollout..."
kubectl rollout status deployment/"$RELEASE_NAME" -n "$NAMESPACE"

log "Pods:"
kubectl get pods -n "$NAMESPACE"

log "Ingress:"
kubectl get ingress -n "$NAMESPACE"

log "Testing HTTP access to http://$EC2_DNS ..."
if curl -s -o /dev/null -w "%{http_code}" "http://$EC2_DNS" | grep -q '^2'; then
  log "✅ App is reachable at http://$EC2_DNS"
else
  log "⚠ App not reachable. Check Ingress setup."
fi