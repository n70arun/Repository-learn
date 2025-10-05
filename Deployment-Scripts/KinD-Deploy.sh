#!/bin/bash
set -e

env_path="/home/n70arun/env-files"

# Usage: ./deploy.sh <env-file>
# Example: ./deploy.sh n8n.env
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <env-file>"
  exit 1
fi

env_file="$env_path/$1"
manifest_file="${1%.env}.yaml"
secret_name="${1%.env}-secret"

# Step 0: Determine namespace from env file
namespace="${1%.env}"

# Resolve script directory and move to manifests
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir/../Manifest_files"

# Check if env file exists
if [[ ! -f "$env_file" ]]; then
  echo "Environment file not found: $env_file"
  exit 1
fi

# Check if manifest file exists
if [[ ! -f "$manifest_file" ]]; then
  echo "Manifest file not found: $manifest_file at $(pwd)"
  exit 1
fi

# Step 1: Create namespace if it doesn't exist
echo "Creating namespace: $namespace (if not exists)..."
kubectl get namespace "$namespace" >/dev/null 2>&1 || \
kubectl create namespace "$namespace"

# Step 2: Create or update Kubernetes Secret from env file
echo "Creating/updating Kubernetes Secret: $secret_name in namespace $namespace..."
kubectl create secret generic "$secret_name" \
  --from-env-file="$env_file" \
  --namespace "$namespace" \
  --dry-run=client -o yaml | kubectl apply -f -

# Step 3: Deploy manifest into cluster in the namespace
echo "Deploying application via $manifest_file with env $env_file in namespace $namespace..."
kubectl apply -f "$manifest_file" -n "$namespace"

echo "Deployment complete. Check pods with: kubectl get pods -n $namespace"
