#!/bin/bash
set -euo pipefail
echo "Checking health of Docker, Kubernetes, Terraform, and Vault..."
docker ps
kubectl get nodes || echo "Kubernetes not running"
terraform version
vault status || echo "Vault not initialized"
