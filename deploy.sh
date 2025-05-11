#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# AI Configuration Options
ENABLE_AI=true    # Set to false to skip AI components
IMPORT_DEMO=true  # Set to false to skip demo workflow import
EXPOSE_AI=false       # Set to true to expose AI services as LoadBalancer

# Function to check if kubectl is connected to the cluster
check_kubectl_connection() {
    echo -e "${BLUE}🔍 Checking connection to Kubernetes cluster...${NC}"
    if ! kubectl get nodes &> /dev/null; then
        echo -e "${RED}❌ Error: Cannot connect to Kubernetes cluster${NC}"
        echo -e "${YELLOW}🔧 Please ensure your Kubernetes cluster is running and kubectl is properly configured${NC}"
        echo ""
        echo -e "${CYAN}💡 If using MicroK8s, try these commands:${NC}"
        echo -e "  ${PURPLE}sudo microk8s start${NC}"
        echo -e "  ${PURPLE}microk8s status${NC}"
        echo ""
        echo -e "${CYAN}💡 To manually configure kubectl for MicroK8s:${NC}"
        echo -e "  ${PURPLE}microk8s config > ~/.kube/config${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Successfully connected to Kubernetes cluster${NC}"
}

# Function to apply Kubernetes manifests with error handling
apply_manifest() {
    local file=$1
    echo -e "${CYAN}📄 Applying ${file}...${NC}"
    if ! kubectl apply -f "$file"; then
        echo -e "${RED}⚠️  Warning: Failed to apply ${file}${NC}"
        echo -e "${YELLOW}🔧 You may need to apply this manifest manually after fixing any issues${NC}"
        echo ""
        read -p "$(echo -e ${YELLOW}Continue with deployment? \(y/n\): ${NC})" choice
        case "$choice" in 
            y|Y ) echo -e "${GREEN}🚀 Continuing deployment...${NC}" ;;
            * ) echo -e "${RED}⛔ Deployment aborted${NC}"; exit 1 ;;
        esac
    fi
}

# Main deployment function
deploy() {
    echo -e "${PURPLE}=================================================${NC}"
    echo -e "${PURPLE}       🚀 n8n AI Platform Deployment 🚀${NC}"
    echo -e "${PURPLE}=================================================${NC}"
    echo ""
    echo -e "${GREEN}🔄 Deploying n8n in queue mode with AI capabilities...${NC}"
    echo ""

    # Check kubectl connection first
    check_kubectl_connection

    echo -e "${CYAN}🧩 Step 1: Creating namespace${NC}"
    apply_manifest namespace.yaml

    echo -e "${CYAN}🧩 Step 2: Setting up secrets${NC}"
    apply_manifest postgresql/postgres-secret.yaml
    apply_manifest n8n/n8n-secret.yaml

    echo -e "${CYAN}🧩 Step 3: Deploying PostgreSQL${NC}"
    apply_manifest postgresql/postgres-configmap.yaml
    apply_manifest postgresql/postgres-claim0-persistentvolumeclaim.yaml
    apply_manifest postgresql/postgres-deployment.yaml
    apply_manifest postgresql/postgres-service.yaml

    echo -e "${CYAN}🧩 Step 4: Deploying Redis for queue${NC}"
    apply_manifest redis/redis-deployment.yaml
    apply_manifest redis/redis-service.yaml

    # Deploy AI components if enabled
    if [ "$ENABLE_AI" = true ]; then
        echo -e "${CYAN}🧩 Step 5: Deploying AI components${NC}"
        
        echo -e "${BLUE}🤖 Setting up Qdrant vector database...${NC}"
        apply_manifest qdrant/qdrant-pvc.yaml
        apply_manifest qdrant/qdrant-deployment.yaml
        apply_manifest qdrant/qdrant-service.yaml
        
        echo -e "${BLUE}🤖 Setting up Ollama LLM service...${NC}"
        apply_manifest ollama/ollama-pvc.yaml
        apply_manifest ollama/ollama-deployment.yaml
        apply_manifest ollama/ollama-service.yaml
        
        # Make the Ollama install script executable
        if [ -f "ollama/install.sh" ]; then
            chmod +x ollama/install.sh
            echo -e "${BLUE}🤖 Running Ollama installation script to pull models...${NC}"
            cd ollama && ./install.sh && cd ..
        fi
    fi

    # Deploy Load Balancer for AI Services
    if [ "$ENABLE_AI" = true ] && [ "$EXPOSE_AI" = true ]; then
        echo -e "${BLUE}🌐 Exposing AI services as LoadBalancer...${NC}"
        kubectl patch svc ollama -n n8n -p '{"spec": {"type": "LoadBalancer"}}'
        kubectl patch svc qdrant -n n8n -p '{"spec": {"type": "LoadBalancer"}}'
        
        # Wait for external IPs
        echo -e "${YELLOW}⏳ Waiting for external IPs to be assigned...${NC}"
        sleep 10
    fi

    echo -e "${CYAN}🧩 Step 6: Deploying n8n main${NC}"
    apply_manifest n8n/n8n-claim0-persistentvolumeclaim.yaml
    
    # Update n8n deployment with environment variables
    if [ "$ENABLE_AI" = true ]; then
        echo -e "${BLUE}🔄 Configuring n8n with AI service endpoints...${NC}"
        # Set up environment variables to connect n8n to Ollama and Qdrant
        kubectl patch -f n8n/n8n-deployment.yaml --local -o yaml --type=json \
            -p='[{"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "OLLAMA_HOST", "value": "ollama.n8n.svc.cluster.local:11434"}}]' | kubectl apply -f -
        kubectl patch -f n8n/n8n-worker-deployment.yaml --local -o yaml --type=json \
            -p='[{"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "OLLAMA_HOST", "value": "ollama.n8n.svc.cluster.local:11434"}}]' | kubectl apply -f -
    else
        apply_manifest n8n/n8n-deployment.yaml
    fi
    
    apply_manifest n8n/n8n-service.yaml

    echo -e "${CYAN}🧩 Step 7: Deploying n8n workers${NC}"
    apply_manifest n8n/n8n-worker-deployment.yaml

    # Deploy demo workflows if enabled
    if [ "$ENABLE_AI" = true ] && [ "$IMPORT_DEMO" = true ]; then
        echo -e "${CYAN}🧩 Step 8: Setting up demo workflows${NC}"
        apply_manifest demo/n8n-demo-configmap.yaml
        apply_manifest demo/n8n-workflow-import-job.yaml
    fi

    # Uncomment to deploy webhook processors
    echo -e "${CYAN}🧩 Step 9: Deploying webhook processors${NC}"
    apply_manifest n8n/n8n-webhook-deployment.yaml
    apply_manifest n8n/n8n-webhook-service.yaml

    # Uncomment to deploy ingress
    echo -e "${CYAN}🧩 Step 10: Deploying ingress${NC}"
    apply_manifest n8n/n8n-ingress.yaml

    # Display pods
    echo ""
    echo -e "${GREEN}✅ Deployment complete! Checking status...${NC}"
    sleep 5
    kubectl get pods -n n8n || echo -e "${YELLOW}⚠️  Could not get pod status. Check connection to cluster.${NC}"

    echo ""
    echo -e "${BLUE}📊 Resource Dashboard${NC}"
    kubectl get deployment -n n8n || echo -e "${YELLOW}⚠️  Could not get deployments.${NC}"
    
    # Get access information
    NODE_PORT=$(kubectl get svc n8n -n n8n -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    OLLAMA_PORT=$(kubectl get svc ollama -n n8n -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    QDRANT_PORT=$(kubectl get svc qdrant -n n8n -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    
    # Generate environment variables for easy access
    echo ""
    echo -e "${PURPLE}=================================================${NC}"
    echo -e "${CYAN}🌐 Service Environment Variables${NC}"
    echo -e "${PURPLE}=================================================${NC}"
    echo -e "# Add these to your shell with: export VARNAME=value"
    echo -e "export N8N_URL=http://localhost:${NODE_PORT:-8080}"
    if [ "$ENABLE_AI" = true ]; then
        echo -e "export OLLAMA_HOST=http://localhost:${OLLAMA_PORT:-11434}"
        echo -e "export QDRANT_URL=http://localhost:${QDRANT_PORT:-6333}"
    fi
    echo -e "${PURPLE}=================================================${NC}"

    echo -e "kubectl set env deployment/n8n -n n8n OLLAMA_HOST=ollama.n8n.svc.cluster.local:11434"
    echo -e "kubectl set env deployment/n8n-worker -n n8n OLLAMA_HOST=ollama.n8n.svc.cluster.local:11434"

    echo ""
    echo -e "${GREEN}🎉 Deployment completed successfully! 🎉${NC}"
    echo -e "${PURPLE}=================================================${NC}"
    echo -e "${CYAN}💻 Access n8n:${NC}"
    if [ -n "$NODE_PORT" ]; then
        echo -e "${GREEN}🔗 http://localhost:${NODE_PORT}${NC}"
    else
        echo -e "${YELLOW}🔍 Run this command to get the NodePort:${NC}"
        echo -e "${PURPLE}   kubectl get svc n8n -n n8n${NC}"
        echo -e "${YELLOW}   Then access: http://localhost:<NodePort>${NC}"
    fi
    
    if [ "$ENABLE_AI" = true ]; then
        echo -e "${PURPLE}=================================================${NC}"
        echo -e "${CYAN}🤖 AI Components:${NC}"
        echo -e "${GREEN}🧠 Ollama LLM: http://localhost:${OLLAMA_PORT:-11434}${NC}"
        echo -e "${GREEN}🔍 Qdrant Vector DB: http://localhost:${QDRANT_PORT:-6333}${NC}"
        echo -e "${YELLOW}💡 API Endpoint for n8n: ollama.n8n.svc.cluster.local:11434${NC}"
    fi
    
    echo -e "${PURPLE}=================================================${NC}"
    echo -e "${BLUE}📝 Need help? Check the README.md for troubleshooting tips${NC}"
}

# Execute deployment
deploy
