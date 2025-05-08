# n8n AI Platform

A Kubernetes-native deployment for n8n with distributed queue mode, providing the foundation for building AI-powered workflows.

## Project Overview

This project builds upon the [n8n-hosting](https://github.com/8gears/n8n-hosting) repository by 8gears, converting it to use n8n's distributed queue mode for better scalability and performance. The platform is designed to serve as a foundation for AI workflow automation, allowing you to integrate your preferred AI components.

### What is n8n AI Platform?

n8n AI Platform is a Kubernetes solution that provides:

- **n8n** - The core workflow automation engine in a distributed setup
- **Scalable architecture** - Using n8n's queue mode with workers and webhook processors
- **Foundation for AI integration** - Ready to connect with your preferred AI services

The platform enables you to build, deploy, and manage scalable workflows on your own infrastructure.

## Repository Structure

The repository is organized into logical components:

```
n8n-ai-platform/
├── n8n/                  # n8n-related manifests
│   ├── n8n-deployment.yaml
│   ├── n8n-worker-deployment.yaml
│   ├── n8n-webhook-deployment.yaml
│   └── ...
├── postgresql/           # PostgreSQL database manifests
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   └── ...
├── redis/                # Redis queue manifests
│   └── redis-deployment.yaml
├── namespace.yaml        # Namespace definition
└── deploy.sh             # Deployment script
```

## Architecture

The n8n AI Platform consists of the following components:

### Core Components
- **n8n Main Instance** - Serves the UI and orchestrates workflows
- **n8n Workers** - Execute the actual workflows in a distributed manner
- **n8n Webhook Processors** (optional) - Handle incoming webhook requests
- **Redis** - Message broker for the queue system
- **PostgreSQL** - Database for storing workflows, credentials, and executions

### AI Integration Points
While this platform doesn't include AI components by default, it's designed to integrate easily with:
- LLM services (like Ollama, LocalAI, or cloud providers)
- Vector databases (such as Qdrant, Milvus, or Chroma)
- Other AI tools through n8n's extensive API capabilities

## Deployment Requirements

### Minimum Requirements
- Kubernetes cluster (K3s, MicroK8s, or any other Kubernetes distribution)
- 2 CPU cores
- 2GB RAM
- 5GB storage for n8n
- 300GB storage for PostgreSQL (as configured in postgresql/postgres-claim0-persistentvolumeclaim.yaml)
- kubectl command-line tool

### Recommended Requirements
- 4+ CPU cores
- 8GB+ RAM
- Storage as configured in the persistent volume claims:
  - 2GB for n8n
  - 300GB for PostgreSQL
  - Additional storage for any AI components you add
- Ingress controller with TLS support

## Deployment Steps

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/n8n-ai-platform.git
cd n8n-ai-platform
```

### 2. Generate Encryption Key
This key will be used by all n8n components to securely access credentials:
```bash
openssl rand -base64 24
```
Update the generated key in `n8n/n8n-secret.yaml`.

### 3. Configure the Deployment
Review and adjust the following files based on your environment:
- `n8n/n8n-deployment.yaml` - Currently configured with:
  - CPU: 0.2 requests, 0.5 limits
  - Memory: 250Mi requests, 640Mi limits
- `postgresql/postgres-deployment.yaml` - Currently configured with:
  - CPU: 1 requests, 4 limits
  - Memory: 2Gi requests, 4Gi limits
- `redis/redis-deployment.yaml` - Currently configured with:
  - CPU: 0.1 requests, 0.3 limits
  - Memory: 128Mi requests, 256Mi limits
- `n8n/n8n-worker-deployment.yaml` - Currently configured with:
  - 2 worker replicas
  - Concurrency: 5
  - CPU: 0.2 requests, 0.5 limits per worker
  - Memory: 250Mi requests, 640Mi limits per worker

### 4. Deploy the Platform
Use the provided deployment script:
```bash
chmod +x deploy.sh
./deploy.sh
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

Alternatively, if you enable the ingress configuration:
```
# Uncomment in deploy.sh
# kubectl apply -f n8n/n8n-ingress.yaml
```

Then add to your /etc/hosts:
```
127.0.0.1 n8n.local
```

And access via:
```
http://n8n.local
```

## Configuration Options

### Queue Mode
The platform is configured to use n8n's queue mode for distributed execution. Key settings:
- `EXECUTIONS_MODE=queue` - Enables queue mode
- Redis as message broker
- Shared encryption key across components

### Scaling
- **Workers**: Currently set to 2 replicas, adjust based on your workload
- **Concurrency**: Set to 5 as recommended in n8n documentation
- **Resources**: Current configuration:
  - Total CPU requests: ~1.7 cores (0.2 + 2×0.2 workers + 1 postgres + 0.1 redis)
  - Total Memory requests: ~2.9GB (250Mi + 2×250Mi workers + 2Gi postgres + 128Mi redis)

### High Availability
For production environments, consider:
- Multiple main instances with `N8N_MULTI_MAIN_SETUP_ENABLED=true`
- Production-ready Redis with persistence (modify `redis/redis-deployment.yaml`)
- Regular backups of PostgreSQL data

## Adding AI Components

This platform is designed to be extended with AI capabilities. Here are some integration options:

### LLM Integration
1. Deploy your preferred LLM service (Ollama, LocalAI, etc.)
2. Connect n8n to the LLM service using HTTP requests or custom nodes

### Vector Database
1. Deploy a vector database like Qdrant
2. Configure n8n workflows to store and retrieve embeddings

### Sample AI Integration Workflow
1. Use n8n HTTP Request nodes to call LLM APIs
2. Process the results within n8n workflows
3. Store data in PostgreSQL or vector databases
4. Create automated AI pipelines for document processing, customer support, etc.

## Known Constraints

- **PostgreSQL Storage**: The current configuration requests 300GB for PostgreSQL, which may be excessive for some environments. Adjust in `postgresql/postgres-claim0-persistentvolumeclaim.yaml`.
- **Resource Sensitivity**: n8n may become unresponsive if resources are insufficient
- **Encryption Key Consistency**: All n8n components must share the same encryption key
- **Database Connections**: Too many workers with low concurrency can exhaust database connections

## Security Considerations

- Generate a strong encryption key
- Consider implementing TLS for all services
- Secure PostgreSQL with strong credentials
- Implement network policies to control pod-to-pod communication

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

- [8gears](https://github.com/8gears) - Original creators of n8n-hosting
- [n8n](https://n8n.io/) - The core workflow automation engine
