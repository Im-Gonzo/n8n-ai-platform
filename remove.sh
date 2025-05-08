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
        exit 1
    fi
    echo -e "${GREEN}✅ Successfully connected to Kubernetes cluster${NC}"
}

# Function to delete resources with error handling
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    
    echo -e "${CYAN}🗑️  Deleting ${resource_type}/${resource_name}...${NC}"
    if ! kubectl delete ${resource_type} ${resource_name} -n ${namespace} 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Resource ${resource_type}/${resource_name} not found or already deleted${NC}"
    else
        echo -e "${GREEN}✅ Successfully deleted ${resource_type}/${resource_name}${NC}"
    fi
}

# Function to confirm removal
confirm_removal() {
    echo -e "${RED}⚠️  WARNING: This will remove ALL n8n AI platform components from your cluster!${NC}"
    echo -e "${YELLOW}⚠️  All data stored in the database, n8n, Ollama models, and vector storage will be lost.${NC}"
    echo ""
    read -p "$(echo -e ${RED}Are you sure you want to continue? \(yes/no\): ${NC})" choice
    case "$choice" in 
        yes ) echo -e "${YELLOW}🚫 Proceeding with removal...${NC}" ;;
        * ) echo -e "${GREEN}✅ Removal cancelled. Your deployment is safe.${NC}"; exit 0 ;;
    esac
}

# Main removal function
remove() {
    echo -e "${PURPLE}=================================================${NC}"
    echo -e "${PURPLE}       🧹 n8n AI Platform Removal 🧹${NC}"
    echo -e "${PURPLE}=================================================${NC}"
    echo ""
    
    # Confirm before proceeding
    confirm_removal
    
    # Check kubectl connection
    check_kubectl_connection
    
    echo -e "${BLUE}📊 Current n8n resources before removal:${NC}"
    kubectl get all -n n8n || echo -e "${YELLOW}⚠️  No resources found in n8n namespace.${NC}"
    echo ""
    
    echo -e "${CYAN}🧩 Step 1: Removing demo components${NC}"
    delete_resource "job" "n8n-workflow-import" "n8n"
    delete_resource "configmap" "n8n-demo-workflows" "n8n"
    
    echo -e "${CYAN}🧩 Step 2: Removing n8n components${NC}"
    # Delete deployments first (in reverse order of creation)
    delete_resource "deployment" "n8n-worker" "n8n"
    delete_resource "deployment" "n8n" "n8n"
    delete_resource "service" "n8n" "n8n"
    delete_resource "persistentvolumeclaim" "n8n-claim0" "n8n"
    delete_resource "ingress" "n8n-ingress" "n8n"
    delete_resource "deployment" "n8n-webhook" "n8n"
    delete_resource "service" "n8n-webhook" "n8n"
    
    echo -e "${CYAN}🧩 Step 3: Removing AI components${NC}"
    # Ollama
    delete_resource "deployment" "ollama" "n8n"
    delete_resource "service" "ollama" "n8n"
    delete_resource "persistentvolumeclaim" "ollama-pvc" "n8n"
    
    # Qdrant
    delete_resource "deployment" "qdrant" "n8n"
    delete_resource "service" "qdrant" "n8n"
    delete_resource "persistentvolumeclaim" "qdrant-pvc" "n8n"
    
    echo -e "${CYAN}🧩 Step 4: Removing Redis components${NC}"
    delete_resource "deployment" "redis" "n8n"
    delete_resource "service" "redis" "n8n"
    
    echo -e "${CYAN}🧩 Step 5: Removing PostgreSQL components${NC}"
    delete_resource "deployment" "postgres" "n8n"
    delete_resource "service" "postgres-service" "n8n"
    delete_resource "persistentvolumeclaim" "postgresql-pv" "n8n"
    delete_resource "configmap" "init-data" "n8n"
    
    echo -e "${CYAN}🧩 Step 6: Removing secrets${NC}"
    delete_resource "secret" "postgres-secret" "n8n"
    delete_resource "secret" "n8n-secret" "n8n"
    
    echo -e "${YELLOW}⏳ Waiting for resources to be removed...${NC}"
    sleep 5
    
    # Check if any resources still exist
    remaining=$(kubectl get all -n n8n 2>/dev/null)
    if [ -n "$remaining" ]; then
        echo -e "${YELLOW}⚠️  Some resources are still being removed:${NC}"
        kubectl get all -n n8n
        echo -e "${YELLOW}💡 You may need to wait longer for complete removal.${NC}"
    else
        echo -e "${GREEN}✅ All resources successfully removed!${NC}"
    fi
    
    # Finally remove the namespace itself (optional)
    echo -e "${BLUE}🤔 Would you like to remove the n8n namespace as well?${NC}"
    echo -e "${YELLOW}⚠️  This will delete ANY remaining resources in the namespace.${NC}"
    read -p "$(echo -e ${YELLOW}Remove namespace? \(yes/no\): ${NC})" choice
    case "$choice" in 
        yes ) 
            echo -e "${CYAN}🗑️  Removing namespace n8n...${NC}"
            kubectl delete namespace n8n
            echo -e "${GREEN}✅ Namespace n8n removed.${NC}"
            ;;
        * )
            echo -e "${BLUE}ℹ️  Keeping namespace n8n. You can remove it later with:${NC}"
            echo -e "${PURPLE}   kubectl delete namespace n8n${NC}"
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}🎉 Removal completed! 🎉${NC}"
    echo -e "${PURPLE}=================================================${NC}"
    echo -e "${BLUE}💾 Data stored in PersistentVolumes may still exist${NC}"
    echo -e "${BLUE}depending on your StorageClass retention policy.${NC}"
    echo -e "${PURPLE}=================================================${NC}"
}

# Execute removal
remove
