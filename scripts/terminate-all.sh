#!/bin/bash
set -euo pipefail
echo "Shutting down Docker containers and Kubernetes clusters..."
docker stop $(docker ps -aq) || true
kind delete clusters $(kind get clusters) || true
minikube stop || true
