# Kind + Helm + Vault-integrated deployment of the Student Tracker app using your Docker image and EC2 DNS ingress

📘 Student Tracker – Kubernetes Deployment (Kind + Helm + Vault)

Welcome to the Kubernetes deployment project for the student-tracker app. This setup uses:
 • Kind for a local multi-node Kubernetes cluster
 • Helm for templated, repeatable Kubernetes deployments
 • Vault for managing secrets securely
 • Ingress NGINX for routing traffic to your app

🔧 Stack Overview

Component Description
Docker Hub Pulls image from biwunor/student-tracker:latest
Vault Injects secrets via environment variables into pods
Helm Manages Deployment, Service, Secret, Ingress
Kind Local multi-node Kubernetes cluster using Docker
Ingress Routes HTTP traffic to / on EC2 DNS hostname

📁 Project Structure

student-tracker-deploy/
├── helm/
│   └── student-tracker/
│       ├── Chart.yaml             # Helm chart metadata
│       ├── values.yaml            # Configuration values
│       └── templates/
│           ├── deployment.yaml    # Kubernetes Deployment
│           ├── ingress.yaml       # Ingress definition
│           ├── secret.yaml        # Vault secrets
│           └── service.yaml       # Kubernetes Service
├── k8s/
│   └── kind-config.yaml           # Kind cluster config (3 nodes)
├── deploy.sh                      # Full automation script
└── README.md                      # This file

🚀 Deployment Instructions

✅ Prerequisites

Ensure the following are installed on your system:
 • Docker
 • Kind
 • kubectl
 • Helm

🔁 1. Start the Cluster & Deploy

Run the following in the project root:

./deploy.sh

What this does:

 1. Creates a Kind cluster with 1 control-plane + 2 workers
 2. Installs the Ingress NGINX controller
 3. Creates the student-tracker and ingress-nginx namespaces
 4. Pulls your Docker Hub image: biwunor/student-tracker:latest
 5. Deploys with Helm using Vault secrets
 6. Waits for pods to be ready
 7. Exposes the app at your EC2 public DNS

🌐 2. Access the App

Your app will be accessible at:

<http://ec2-54-170-56-216.eu-west-1.compute.amazonaws.com/>

Test it:

curl <http://ec2-54-170-56-216.eu-west-1.compute.amazonaws.com/>

🔐 Vault Integration

The following Vault credentials are securely injected into your pods:

VAULT_ADDR:      <http://44.204.193.107:8200>
VAULT_ROLE_ID:   f7af58b1-5c22-7c2d-c659-0425d9ce94b2
VAULT_SECRET_ID: d5f736da-785b-8f5c-9258-48d5d7c43c06

These values are stored as a Kubernetes Secret and mounted into the deployment via environment variables.

⚙ Helm Chart Details

Chart path: helm/student-tracker/

Key values in values.yaml:

image:
  repository: biwunor/student-tracker
  tag: latest

vault:
  VAULT_ADDR: <http://44.204.193.107:8200>
  VAULT_ROLE_ID: f7af58b1-5c22-7c2d-c659-0425d9ce94b2
  VAULT_SECRET_ID: d5f736da-785b-8f5c-9258-48d5d7c43c06

ingress:
  host: ec2-54-170-56-216.eu-west-1.compute.amazonaws.com

You can override any values by using:

helm upgrade --install student-tracker helm/student-tracker \
  --namespace student-tracker \
  --set image.tag=prod \
  --set vault.VAULT_ADDR=<http://vault:8200>

🔎 Troubleshooting

❌ Ingress not routing

Check if ingress controller is running:

kubectl get pods -n ingress-nginx

Ensure the ingress hostname matches your EC2 DNS name:

kubectl describe ingress student-tracker-ingress -n student-tracker

❌ Vault not injecting secrets

Check if secret exists:

kubectl get secret vault-secrets -n student-tracker -o yaml

View pod logs to debug:

kubectl logs deployment/student-tracker -n student-tracker

✅ Useful Commands

View deployed resources:

kubectl get all -n student-tracker

Restart app:

kubectl rollout restart deployment student-tracker -n student-tracker

Uninstall everything:

kind delete cluster --name student-tracker

📄 License

MIT License. Feel free to modify and adapt.

👥 Maintainers

Name                Contact
Bonaventre Simeon   <contact@bonaventure.org.ng>
![Deploy](https://github.com/bonaventuresimeon/actions/workflows/deploy.yaml/badge.svg)
