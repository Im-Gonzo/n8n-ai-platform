# Demo Workflows for n8n AI Platform

This directory contains sample workflows and tools to demonstrate the AI capabilities of the n8n AI Platform.

## Contents

- `n8n-demo-configmap.yaml` - ConfigMap containing demo workflow definitions
- `n8n-workflow-import-job.yaml` - Kubernetes job to import workflows into n8n
- `manual-import.sh` - Script to manually import workflows if the job fails

## Manual Import

If the automatic workflow import doesn't work, you can use the manual import script:

1. Make the script executable:
   ```bash
   chmod +x manual-import.sh
   ```

2. Run the script:
   ```bash
   ./manual-import.sh
   ```

The script will:
- Create the necessary n8n credentials for Ollama
- Import a demo workflow that uses Ollama
- Set up the connections between components

## AI Demo Workflow

The demo workflow includes:

1. **Chat Trigger** - Provides a conversational interface to the AI
2. **Basic LLM Chain** - Chains the user input to the language model
3. **Ollama Chat Model** - Uses the Ollama service to generate responses

## Troubleshooting

If you encounter issues with the workflow:

1. **Credential Errors**: You may need to manually reconfigure the Ollama credential
   - Open the workflow in n8n
   - Click on the Ollama Chat Model node
   - Go to the credentials tab and reconfigure it with these settings:
     - Host: ollama.n8n.svc.cluster.local
     - Port: 11434

2. **Missing LangChain Nodes**: Install the LangChain nodes package
   - In n8n, go to Settings → Community Nodes
   - Search for "n8n-nodes-langchain"
   - Install the package
