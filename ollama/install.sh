#!/bin/bash

# Apply Ollama resources
kubectl apply -f ollama-pvc.yaml
kubectl apply -f ollama-deployment.yaml
kubectl apply -f ollama-service.yaml

# Wait for Ollama to be running
echo "Waiting for Ollama to start..."
kubectl wait --for=condition=available --timeout=300s deployment/ollama -n n8n

# Get the Ollama pod name
OLLAMA_POD=$(kubectl get pod -n n8n -l app=ollama -o jsonpath='{.items[0].metadata.name}')

# Execute command to pull the model
echo "Pulling llama3.2 model..."
kubectl exec -n n8n $OLLAMA_POD -- ollama pull llama3.2

echo "Ollama setup complete!"
