#!/bin/bash

###############################################################################
# Title:      Full Cloud & DevOps Suite Installer for Ubuntu
# Author:     Bonaventure Simeon - Cloud & Legal Engineer
# Description: This script automates the installation of a comprehensive suite
#              of Cloud, DevOps, Infrastructure-as-Code (IaC), and Monitoring
#              tools optimized for enterprise environments.
# Target OS:  Ubuntu 20.04 / 22.04+
# Usage:      sudo ./full_devops_suite.sh
###############################################################################

set -euo pipefail

echo "🚀 Updating and upgrading system..."
sudo apt update -y && sudo apt full-upgrade -y && sudo apt autoremove -y

echo "📦 Installing core dependencies..."
sudo apt install -y \
    ca-certificates curl gnupg lsb-release \
    software-properties-common apt-transport-https \
    unzip wget git jq python3 python3-pip logrotate htop net-tools

# Install yq
sudo snap install yq

############################################
# Docker & Compose
############################################
echo "🐳 Installing Docker Engine & Compose..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER

############################################
# Kubernetes Toolchain
############################################
echo "☸️ Installing Kubernetes CLI tools..."

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# kubeval
wget https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz
tar -xzf kubeval-linux-amd64.tar.gz && sudo mv kubeval /usr/local/bin/ && rm kubeval-linux-amd64.tar.gz

# Kind
curl -Lo kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x kind && sudo mv kind /usr/local/bin/

# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# K9s
curl -sS https://webinstall.dev/k9s | bash

############################################
# HashiCorp Stack
############################################
echo "🔐 Installing HashiCorp Terraform, Vault, and Packer..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

sudo apt update && sudo apt install -y terraform vault packer

############################################
# Cloud CLI Tools
############################################
echo "☁️ Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install && rm -rf aws awscliv2.zip

############################################
# Configuration Management
############################################
echo "📦 Installing Ansible..."
sudo apt install -y ansible

############################################
# Monitoring & Optimization Tools
############################################
echo "📊 Launching Prometheus & Grafana via Docker..."
docker run -d --restart unless-stopped --name=grafana -p 3000:3000 grafana/grafana
docker run -d --restart unless-stopped --name=prometheus -p 9090:9090 prom/prometheus

echo "💸 Deploying Kubecost (if cluster active)..."
kubectl create namespace kubecost || true
helm repo add kubecost https://kubecost.github.io/cost-analyzer/ && helm repo update
helm install kubecost kubecost/cost-analyzer --namespace kubecost --set kubecostToken="demo" || true

############################################
# Maintenance & Control Scripts
############################################
echo "🧠 Creating health check script..."
cat << 'EOF' | sudo tee /usr/local/bin/devops-healthcheck > /dev/null
#!/bin/bash
echo "🔍 Docker Containers:"
docker ps
echo "🔍 Kubernetes Nodes:"
kubectl get nodes || echo "Kubernetes not available."
echo "🔍 Disk Usage:"
df -h
echo "🔍 Memory:"
free -m
EOF
sudo chmod +x /usr/local/bin/devops-healthcheck

echo "🛑 Creating universal termination script..."
cat << 'EOF' | sudo tee /usr/local/bin/terminate-all > /dev/null
#!/bin/bash
echo "⚠️ Terminating all Docker containers..."
docker stop \$(docker ps -q) || true
echo "🧨 Deleting Kind & Minikube clusters..."
kind delete cluster || true
minikube delete || true
echo "✅ Environment shutdown complete."
EOF
sudo chmod +x /usr/local/bin/terminate-all

############################################
# Final Steps
############################################
echo "✅ All tools installed successfully!"
echo "🔍 Run 'devops-healthcheck' for system diagnostics."
echo "🛑 Run 'terminate-all' to stop all running services."
echo "🔁 Please reboot for Docker group changes to take effect."

