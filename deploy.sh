#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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
    echo -e "${GREEN}🔄 Deploying n8n in queue mode...${NC}"
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

    echo -e "${CYAN}🧩 Step 5: Deploying n8n main${NC}"
    apply_manifest n8n/n8n-claim0-persistentvolumeclaim.yaml
    apply_manifest n8n/n8n-deployment.yaml
    apply_manifest n8n/n8n-service.yaml

    echo -e "${CYAN}🧩 Step 6: Deploying n8n workers${NC}"
    apply_manifest n8n/n8n-worker-deployment.yaml

    echo -e "${YELLOW}💡 Optional Components (commented out)${NC}"
    echo -e "${YELLOW}💡 Uncomment in script to deploy:${NC}"
    echo -e "${YELLOW}   - Webhook processors (for high request volume)${NC}"
    echo -e "${YELLOW}   - Ingress (for external access using domain name)${NC}"
    # Uncomment to deploy webhook processors
    # echo -e "${CYAN}🧩 Step 7: Deploying webhook processors${NC}"
    # apply_manifest n8n/n8n-webhook-deployment.yaml
    # apply_manifest n8n/n8n-webhook-service.yaml

    # Uncomment to deploy ingress
    # echo -e "${CYAN}🧩 Step 8: Deploying ingress${NC}"
    # apply_manifest n8n/n8n-ingress.yaml

    # Display pods
    echo ""
    echo -e "${GREEN}✅ Deployment complete! Checking status...${NC}"
    sleep 5
    kubectl get pods -n n8n || echo -e "${YELLOW}⚠️  Could not get pod status. Check connection to cluster.${NC}"

    echo ""
    echo -e "${BLUE}📊 Resource Dashboard${NC}"
    kubectl get deployment -n n8n || echo -e "${YELLOW}⚠️  Could not get deployments.${NC}"
    
    # Get NodePort
    NODE_PORT=$(kubectl get svc n8n -n n8n -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    
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
    echo -e "${YELLOW}🔗 Or if you deployed the ingress, access at: http://n8n.local${NC}"
    echo -e "${YELLOW}   (Ensure n8n.local is in your /etc/hosts)${NC}"
    echo -e "${PURPLE}=================================================${NC}"
    echo -e "${BLUE}📝 Need help? Check the README.md for troubleshooting tips${NC}"
}

# Execute deployment
deploy
