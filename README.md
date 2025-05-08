# n8n AI Platform

A Kubernetes-native deployment for n8n with distributed queue mode and integrated AI components, providing a complete self-hosted platform for AI-powered workflows.

## Project Overview

This project combines n8n workflow automation with AI capabilities in a Kubernetes-native deployment. It's based on 8gears' [n8n-hosting](https://github.com/8gears/n8n-hosting) and [self-hosted-ai-starter-kit](https://github.com/8gears/self-hosted-ai-starter-kit), but fully adapted for Kubernetes with enhanced scalability features.

### What is n8n AI Platform?

n8n AI Platform is a comprehensive Kubernetes solution that combines:

- **n8n** - The core workflow automation engine in a distributed queue setup
- **Ollama** - Local Large Language Model (LLM) service with NVIDIA GPU support
- **Qdrant** - Vector database for embeddings and semantic search
- **PostgreSQL** - Database for storing workflows and data
- **Redis** - Queue system for distributed processing

This platform enables you to build, deploy, and manage AI workflows entirely on your own infrastructure.

## Repository Structure

The repository is organized into logical components:

```
n8n-ai-platform/
├── n8n/                  # n8n-related manifests
│   ├── n8n-deployment.yaml
│   ├── n8n-worker-deployment.yaml
│   └── ...
├── ollama/               # Ollama LLM service manifests
│   ├── ollama-deployment.yaml
│   ├── install.sh
│   └── ...
├── qdrant/               # Qdrant vector database manifests
│   ├── qdrant-deployment.yaml
│   └── ...
├── postgresql/           # PostgreSQL database manifests
├── redis/                # Redis queue manifests
├── demo/                 # Sample workflows and configurations
├── deploy.sh             # Main deployment script
└── remove.sh             # Cleanup script
```

## Architecture

### Core Components

- **n8n Main Instance** - Serves the UI and orchestrates workflows
- **n8n Workers** - Execute workflows in a distributed manner
- **Ollama** - Provides LLM capabilities (with NVIDIA GPU support)
- **Qdrant** - Vector database for embeddings storage and retrieval
- **Redis** - Message broker for the queue system
- **PostgreSQL** - Database for storing workflows, credentials, and executions

### System Design

- All components run in a dedicated `n8n` namespace
- Components communicate via Kubernetes services
- Persistent storage is used for all stateful components
- Distributed architecture with queue mode for scalability

## Deployment Requirements

### Minimum Requirements
- Kubernetes cluster (K3s, MicroK8s, or any other distribution)
- 4 CPU cores
- 8GB RAM
- 20GB storage
- NVIDIA GPU with 10GB+ VRAM

### Recommended Requirements
- 8+ CPU cores
- 16GB+ RAM
- 50GB+ storage
- NVIDIA GPU with 10GB+ VRAM

## Deployment Steps

### 1. Clone the Repository
```bash
git clone https://github.com/Im-Gonzo/n8n-ai-platform.git
cd n8n-ai-platform
```

### 2. Configure the Deployment

Customize the deployment by editing the configuration at the top of `deploy.sh`:

```bash
# AI Configuration Options
ENABLE_AI=true    # Set to false to skip AI components
IMPORT_DEMO=true  # Set to false to skip demo workflow import
```

### 3. Deploy the Platform

Make the deployment script executable and run it:
```bash
chmod +x deploy.sh
./deploy.sh
```

This will:
- Create the necessary namespace
- Deploy all components
- Configure n8n to connect to AI services
- Deploy sample workflows (if enabled)
- Show access URLs and environment variables

### 4. Access the Platform

After deployment, you'll see access URLs for all services:

- n8n: http://localhost:<NodePort>

## Sample Workflows

The platform includes a sample workflow that demonstrates:

- Using Ollama for text generation
- Basic LLM chain implementation
- Conversation handling via chat triggers

To import custom workflows, use the n8n UI or the CLI within the n8n pod.

## Scaling the Platform

### Worker Scaling

Increase the number of n8n workers to handle more concurrent workflows:

```bash
kubectl scale deployment n8n-worker -n n8n --replicas=3
```

### Resource Allocation

Adjust resource limits in the deployment files based on your workload and available resources.

## Troubleshooting

### Common Issues

1. **NVIDIA GPU Issues**: 
   - Verify GPU is detected: `kubectl exec -n n8n <ollama-pod> -- nvidia-smi`

2. **Model Download Issues**:
   - Check Ollama logs: `kubectl logs -n n8n <ollama-pod>`
   - Download models manually using the commands in the AI Components section

3. **n8n Connection Issues**:
   - Verify environment variables: `kubectl describe deployment n8n -n n8n`
   - Ensure services are correctly named and accessible

### Additional Resources

For component-specific troubleshooting, check:
- [Ollama Documentation](https://github.com/ollama/ollama)
- [Qdrant Documentation](https://qdrant.tech/documentation/)
- [n8n Documentation](https://docs.n8n.io/)

## Removing the Platform

To remove all deployed components:

```bash
chmod +x remove.sh
./remove.sh
```

This will remove all resources from the `n8n` namespace.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgements

- [8gears](https://github.com/8gears) - Original creators of n8n-hosting and self-hosted-ai-starter-kit
- [n8n](https://n8n.io/) - The core workflow automation engine
- [Ollama](https://ollama.ai/) - For the local LLM capabilities
- [Qdrant](https://qdrant.tech/) - For the vector database functionality
