# n8n AI Platform

A Kubernetes-native deployment that combines n8n workflow automation with AI capabilities, providing a complete self-hosted AI orchestration platform.

## Project Overview

This project builds upon the [n8n-hosting](https://github.com/8gears/n8n-hosting) repository by 8gears and integrates components from their [self-hosted-ai-starter-kit](https://github.com/8gears/self-hosted-ai-starter-kit), converting the Docker-based AI stack into a fully Kubernetes-native solution.

### What is n8n AI Platform?

n8n AI Platform is a comprehensive Kubernetes solution that combines:

- **n8n** - The core workflow automation engine
- **Scalable architecture** - Using n8n's distributed queue mode
- **AI components** - Including LLM services, vector database
- **Production-ready configuration** - With proper resource allocation and scaling capabilities

The platform enables you to build, deploy, and manage AI workflows entirely on your own infrastructure.

## Architecture

The n8n AI Platform consists of the following components:

### Core Components
- **n8n Main Instance** - Serves the UI and orchestrates workflows
- **n8n Workers** - Execute the actual workflows in a distributed manner
- **n8n Webhook Processors** (optional) - Handle incoming webhook requests
- **Redis** - Message broker for the queue system
- **PostgreSQL** - Database for storing workflows, credentials, and executions

### AI Stack Components
- **LLM Service** - For text generation and processing
- **Qdrant** - Vector database for embedding storage and retrieval
- **Optional AI Tools** - Additional services can be added based on requirements

## Deployment Requirements

### Minimum Requirements
- Kubernetes cluster (K3s, MicroK8s, or any other Kubernetes distribution)
- 4 CPU cores
- 8GB RAM
- 20GB storage
- kubectl command-line tool

### Recommended Requirements
- 8+ CPU cores
- 16GB+ RAM
- 50GB+ storage 
- Node with GPU support (for LLM inference)

## Deployment Steps

### 1. Clone the Repository
```bash
git clone https://github.com/Im-Gonzo/n8n-ai-platform.git
cd n8n-ai-platform
```

### 2. Generate Encryption Key
This key will be used by all n8n components to securely access credentials:
```bash
openssl rand -base64 24
```
Update the generated key in `kubernetes/n8n-secret.yaml`.

### 3. Configure the Deployment
Review and adjust the following files based on your environment:
- `kubernetes/n8n-deployment.yaml` - Resource limits, environment variables
- `kubernetes/n8n-worker-deployment.yaml` - Number of workers, concurrency
- `kubernetes/postgres-secret.yaml` - Database credentials
- `kubernetes/redis-deployment.yaml` - Redis configuration

### 4. Deploy the Platform
Use the provided deployment script:
```bash
chmod +x kubernetes/deploy.sh
./kubernetes/deploy.sh
```

Or deploy manually:
```bash
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/postgres-secret.yaml
kubectl apply -f kubernetes/n8n-secret.yaml
kubectl apply -f kubernetes/postgres-configmap.yaml
kubectl apply -f kubernetes/postgres-claim0-persistentvolumeclaim.yaml
kubectl apply -f kubernetes/postgres-deployment.yaml
kubectl apply -f kubernetes/postgres-service.yaml
kubectl apply -f kubernetes/redis-deployment.yaml
kubectl apply -f kubernetes/redis-service.yaml
kubectl apply -f kubernetes/n8n-claim0-persistentvolumeclaim.yaml
kubectl apply -f kubernetes/n8n-deployment.yaml
kubectl apply -f kubernetes/n8n-service.yaml
kubectl apply -f kubernetes/n8n-worker-deployment.yaml
```

### 5. Access n8n Dashboard
Get the NodePort for the n8n service:
```bash
kubectl get svc -n n8n n8n
```

Access the dashboard at:
```
http://localhost:<NodePort>
```

## Configuration Options

### Queue Mode
The platform is configured to use n8n's queue mode for distributed execution. Key settings:
- `EXECUTIONS_MODE=queue` - Enables queue mode
- Redis as message broker
- Shared encryption key across components

### Scaling
- **Workers**: Adjust the number of replicas in `n8n-worker-deployment.yaml`
- **Concurrency**: Set by `--concurrency=5` parameter in worker containers
- **Resources**: Set appropriate CPU/memory limits in deployment files

### High Availability
For production environments, consider:
- Multiple main instances with `N8N_MULTI_MAIN_SETUP_ENABLED=true`
- Production-ready Redis with persistence
- Regular backups of PostgreSQL data

## Known Constraints

- **PostgreSQL Limitations**: Running with SQLite instead of PostgreSQL is not recommended for queue mode
- **Resource Sensitivity**: n8n may become unresponsive if resources are insufficient
- **Encryption Key Consistency**: All n8n components must share the same encryption key
- **Database Connections**: Too many workers with low concurrency can exhaust database connections
- **MicroK8s Constraints**: For local development with MicroK8s, enable necessary addons (storage, dns)

## Security Considerations

- Generate a strong encryption key
- Consider implementing TLS for all services
- Secure PostgreSQL with strong credentials
- Implement network policies to control pod-to-pod communication
- Consider using a service mesh for more advanced security features

## Troubleshooting

### Common Issues
- **Pending Pods**: Usually indicates resource constraints
- **Database Connection Issues**: Check PostgreSQL service and credentials
- **Redis Connectivity**: Ensure Redis is running and accessible
- **n8n Worker Connection**: Verify encryption key is consistent

### Debugging
- Check pod logs: `kubectl logs -n n8n <pod-name>`
- Check pod descriptions: `kubectl describe pod -n n8n <pod-name>`
- Access n8n logs in the UI: Settings → Log Streaming

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgements

- [8gears](https://github.com/8gears) - Original creators of n8n-hosting and self-hosted-ai-starter-kit
- [n8n](https://n8n.io/) - The core workflow automation engine
