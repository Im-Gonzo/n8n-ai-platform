#!/bin/bash
set -e

# Deploy n8n with queue mode
echo "Deploying n8n in queue mode..."

# Create namespace
kubectl apply -f namespace.yaml

# Apply secrets
kubectl apply -f postgres-secret.yaml
kubectl apply -f n8n-secret.yaml

# Deploy PostgreSQL
kubectl apply -f postgres-configmap.yaml
kubectl apply -f postgres-claim0-persistentvolumeclaim.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# Deploy Redis for queue
kubectl apply -f redis-deployment.yaml
kubectl apply -f redis-service.yaml

# Deploy n8n main
kubectl apply -f n8n-claim0-persistentvolumeclaim.yaml
kubectl apply -f n8n-deployment.yaml
kubectl apply -f n8n-service.yaml

# Deploy n8n workers
kubectl apply -f n8n-worker-deployment.yaml

# Optional: Deploy webhook processors
# Uncomment if you want to use webhook processors
# kubectl apply -f n8n-webhook-deployment.yaml
# kubectl apply -f n8n-webhook-service.yaml

# Display pods
echo "Deployment complete. Checking status..."
sleep 5
kubectl get pods -n n8n

echo ""
echo "Access n8n at: http://localhost:<node-port>"
echo "Get the NodePort with: kubectl get svc n8n -n n8n"
