# AI Integration Plan for n8n-ai-platform

This document outlines the plan to integrate AI capabilities from the [self-hosted-ai-starter-kit](https://github.com/8gears/self-hosted-ai-starter-kit) into our Kubernetes-based n8n-ai-platform.

## 🔍 Analysis of self-hosted-ai-starter-kit

The self-hosted-ai-starter-kit includes the following key AI components:

1. **Ollama**: Local Large Language Model (LLM) service
   - Uses llama3.2 model by default
   - Has separate configurations for CPU and GPU (NVIDIA/AMD) deployments

2. **Qdrant**: Vector database for embeddings storage
   - Used for semantic search and retrieval
   - Persistent storage for vector data

3. **n8n Workflows**:
   - Uses LangChain nodes for AI interactions
   - Demo workflow with Chat Trigger → Basic LLM Chain → Ollama Chat Model
   - Credentials for Ollama and Qdrant services

## 🎯 Integration Goals

1. Add Ollama and Qdrant as Kubernetes deployments
2. Configure n8n to interact with these AI services
3. Support both CPU and GPU deployment options
4. Provide sample workflows for AI capabilities
5. Maintain scalability and production-readiness

## 📋 Implementation Plan

### Phase 1: Add AI Component Manifests

1. **Create directory structure**:
   ```
   n8n-ai-platform/
   ├── ollama/                # Ollama manifests
   │   ├── ollama-deployment.yaml
   │   ├── ollama-service.yaml
   │   └── ollama-pvc.yaml
   ├── qdrant/                # Qdrant manifests
   │   ├── qdrant-deployment.yaml
   │   ├── qdrant-service.yaml
   │   └── qdrant-pvc.yaml
   ```

2. **Create Ollama deployment manifests**:
   - Base CPU deployment
   - GPU variants using node selectors and resource limits
   - Init container to pull Llama model

3. **Create Qdrant deployment manifests**:
   - Deployment with proper resource allocation
   - Persistent storage configuration
   - Service definition for n8n access

### Phase 2: Update Configuration

1. **Update n8n configuration**:
   - Add environment variables for Ollama connection
   - Add environment variables for Qdrant connection
   - Update n8n-secret.yaml with required credentials

2. **Create ConfigMaps for AI settings**:
   - Models configuration
   - Connection settings

3. **Update the deployment script**:
   - Add AI components deployment options
   - Add feature flags for CPU/GPU selection

### Phase 3: Import Sample Workflows

1. **Create workflow importer**:
   - Add mechanism to import demo workflows
   - Configure credentials automatically

2. **Add sample workflows**:
   - Basic chat workflow
   - Document Q&A workflow
   - Vector search example

### Phase 4: Documentation

1. **Update README.md**:
   - Document AI capabilities
   - Explain available models
   - Provide usage examples

2. **Create AI-specific guides**:
   - How to use LLMs with n8n
   - How to use Vector Search with Qdrant
   - Performance tuning tips

## 📝 Detailed Tasks

### 1. Ollama Deployment

#### ollama-deployment.yaml (CPU version)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama
  namespace: n8n
  labels:
    app: ollama
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ollama
  template:
    metadata:
      labels:
        app: ollama
    spec:
      containers:
      - name: ollama
        image: ollama/ollama:latest
        ports:
        - containerPort: 11434
        resources:
          requests:
            cpu: "1"
            memory: "4Gi"
          limits:
            cpu: "4"
            memory: "8Gi"
        volumeMounts:
        - name: ollama-data
          mountPath: /root/.ollama
      initContainers:
      - name: ollama-model-puller
        image: ollama/ollama:latest
        command: ["/bin/sh", "-c"]
        args:
        - "mkdir -p /root/.ollama && ollama pull llama3.2"
        volumeMounts:
        - name: ollama-data
          mountPath: /root/.ollama
      volumes:
      - name: ollama-data
        persistentVolumeClaim:
          claimName: ollama-pvc
```

#### ollama-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ollama
  namespace: n8n
  labels:
    app: ollama
spec:
  ports:
  - port: 11434
    targetPort: 11434
    name: http
  selector:
    app: ollama
```

### 2. Qdrant Deployment

#### qdrant-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: qdrant
  namespace: n8n
  labels:
    app: qdrant
spec:
  replicas: 1
  selector:
    matchLabels:
      app: qdrant
  template:
    metadata:
      labels:
        app: qdrant
    spec:
      containers:
      - name: qdrant
        image: qdrant/qdrant:latest
        ports:
        - containerPort: 6333
        - containerPort: 6334
        resources:
          requests:
            cpu: "0.5"
            memory: "1Gi"
          limits:
            cpu: "2"
            memory: "4Gi"
        volumeMounts:
        - name: qdrant-data
          mountPath: /qdrant/storage
      volumes:
      - name: qdrant-data
        persistentVolumeClaim:
          claimName: qdrant-pvc
```

#### qdrant-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: qdrant
  namespace: n8n
  labels:
    app: qdrant
spec:
  ports:
  - port: 6333
    targetPort: 6333
    name: http
  - port: 6334
    targetPort: 6334
    name: grpc
  selector:
    app: qdrant
```

### 3. Update n8n Deployment

Add these environment variables to n8n-deployment.yaml:
```yaml
- name: OLLAMA_HOST
  value: "ollama.n8n.svc.cluster.local:11434"
```

### 4. Import Demo Workflows

Create a Kubernetes Job for workflow import:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: n8n-workflow-import
  namespace: n8n
spec:
  template:
    spec:
      containers:
      - name: n8n-import
        image: n8nio/n8n:latest
        command: ["/bin/sh", "-c"]
        args:
        - "n8n import:credentials --separate --input=/demo-data/credentials && n8n import:workflow --separate --input=/demo-data/workflows"
        volumeMounts:
        - name: demo-data
          mountPath: /demo-data
        env:
        # Same env variables as n8n main deployment
      volumes:
      - name: demo-data
        configMap:
          name: n8n-demo-workflows
      restartPolicy: Never
  backoffLimit: 4
```

## 🚩 Deployment Flags

For the enhanced deploy.sh, add these AI-specific options:

```bash
# Enable AI components
AI_ENABLED=true

# LLM Options: cpu, gpu-nvidia, gpu-amd
LLM_MODE=cpu

# Model to pull
LLM_MODEL=llama3.2
```

## 📊 Resource Requirements

| Component | CPU (Requests) | Memory (Requests) | Storage |
|-----------|---------------|------------------|---------|
| Ollama (CPU) | 1 core | 4Gi | 10Gi |
| Ollama (GPU) | 1 core | 6Gi | 10Gi |
| Qdrant | 0.5 core | 1Gi | 5Gi |

## 🔍 Next Steps

1. Create the AI component manifests outlined above
2. Update the deploy.sh script to include AI options
3. Create demo workflow ConfigMaps
4. Update documentation with AI capabilities
5. Test and validate the complete solution
