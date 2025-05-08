# Ollama for n8n AI Platform

This directory contains Kubernetes manifests for deploying Ollama LLM services within the n8n AI Platform.

## Files

- `ollama-deployment.yaml`: The main Ollama deployment file (supports both GPU and CPU)
- `ollama-pvc.yaml`: Persistent volume claim for Ollama models
- `ollama-service.yaml`: Service for accessing Ollama

## GPU Support

The deployment file includes GPU support with NVIDIA GPUs. By default, the nodeSelector for GPU is commented out and can be enabled in the deploy.sh script by setting:

```bash
ENABLE_GPU=true
```

If you don't have nodes labeled with `accelerator=nvidia`, you can label them with:

```bash
kubectl label nodes <your-node-name> accelerator=nvidia
```

## Troubleshooting

### Common Issues

1. **Pending Pod Status**
   - Check for PVC-related issues: `kubectl describe pvc ollama-pvc -n n8n`
   - Ensure your storage class supports the requested volume size

2. **Init Container Failures**
   - The init container is designed to download the LLM model before the main container starts
   - View logs: `kubectl logs -n n8n <pod-name> -c ollama-model-puller`
   - Common fix: The initialization script may need more time to start Ollama before pulling models

3. **Node Selector Issues**
   - For GPU deployment, ensure your nodes are properly labeled with `accelerator=nvidia`
   - Add labels: `kubectl label nodes <node-name> accelerator=nvidia`
   - If you don't have GPU nodes, make sure to set `ENABLE_GPU=false` in deploy.sh

4. **Resource Constraints**
   - Ollama requires significant memory (4GB+) and CPU resources
   - If your cluster has limited resources, reduce requests/limits in the deployment

### Adjusting Model Size

The default model is llama3.2, but you can use smaller models if resource-constrained:

1. Edit the `ollama-deployment.yaml` file:
```yaml
args:
- "mkdir -p /root/.ollama && sleep 10 && ollama serve & sleep 5 && ollama pull tinyllama && pkill ollama"
```

2. Apply the changes:
```bash
kubectl apply -f ollama-deployment.yaml
```

## Manually Testing Ollama

Once deployed, you can manually test the Ollama service:

1. Port-forward the service:
```bash
kubectl port-forward svc/ollama -n n8n 11434:11434
```

2. Test with curl:
```bash
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "What is artificial intelligence?"
}'
```

3. Or using the Ollama CLI from another pod:
```bash
kubectl run -it --rm ollama-test --image=ollama/ollama -- /bin/sh
# Then inside the pod:
ollama run llama3.2 "What is artificial intelligence?"
```
