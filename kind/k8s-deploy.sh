#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="student-tracker"
KIND_CONFIG="k8s/kind-config.yaml"
K8S_DIR="k8s"
NAMESPACE="student-tracker"
INGRESS_NAMESPACE="ingress-nginx"
INGRESS_MANIFEST_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml"
EC2_DNS="ec2-54-170-56-216.eu-west-1.compute.amazonaws.com"

log() {
  echo "[$(date --iso-8601=seconds)] $*"
}

log "✅ Starting Deployment..."

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  log "Kind cluster '$CLUSTER_NAME' already exists."
else
  log "Creating Kind cluster '$CLUSTER_NAME'..."
  kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
fi

kubectl config use-context "kind-$CLUSTER_NAME"

for ns in "$NAMESPACE" "$INGRESS_NAMESPACE"; do
  if kubectl get namespace "$ns" >/dev/null 2>&1; then
    log "Namespace '$ns' already exists."
  else
    kubectl create namespace "$ns"
  fi
done

if ! kubectl get deployment ingress-nginx-controller -n "$INGRESS_NAMESPACE" >/dev/null 2>&1; then
  log "Deploying ingress-nginx controller..."
  kubectl apply --validate=false -f "$INGRESS_MANIFEST_URL"
  kubectl rollout status deployment/ingress-nginx-controller -n "$INGRESS_NAMESPACE"
else
  log "Ingress controller already deployed."
fi

log "Patching ingress service to LoadBalancer..."
kubectl patch svc ingress-nginx-controller -n "$INGRESS_NAMESPACE" --type='merge' -p '{"spec":{"type":"LoadBalancer"}}' || true

log "Applying manifests from $K8S_DIR..."
kubectl apply -n "$NAMESPACE" --validate=false -f "$K8S_DIR/vault-secret.yaml"
kubectl apply -n "$NAMESPACE" --validate=false -f "$K8S_DIR/deployment.yaml"
kubectl apply -n "$NAMESPACE" --validate=false -f "$K8S_DIR/service.yaml"
kubectl apply -n "$NAMESPACE" --validate=false -f "$K8S_DIR/ingress.yaml"

log "Waiting for Deployment rollout to complete..."
kubectl rollout status deployment/student-tracker -n "$NAMESPACE"

log "✅ Resources:"
kubectl get pods -n "$NAMESPACE"
kubectl get svc -n "$NAMESPACE"
kubectl get ingress -n "$NAMESPACE"

log "🌐 Testing access to http://$EC2_DNS ..."
if curl -s -o /dev/null -w "%{http_code}" "http://$EC2_DNS" | grep -q '^2'; then
  log "🎉 App is accessible via Ingress!"
else
  log "⚠ App might not be reachable yet. Check DNS, firewall, and ingress logs."
fi

log "✅ Deployment complete."