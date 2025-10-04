#!/bin/ash
set -e

env_path="/Users/arun/Desktop"

# Usage: ./deploy.sh <env-file>
# Example: ./deploy.sh npm.env

if [ $# -ne 1 ]; then
  echo "Usage: $0 <env-file>"
  exit 1
fi

env_file="$env_path/$1"
manifest_file=`echo $1 | sed 's/\.env$/.yaml/'`

# Change to Manifest_files directory
cd "$(pwd)/../Manifest_files"

# Check if env file exists
if [ ! -f "$env_file" ]; then
  echo "Environment file not found: $env_file"
  exit 1
fi

# Check if manifest file exists
if [ ! -f "$manifest_file" ]; then
  echo "Manifest file not found: $manifest_file at $(pwd)"
  exit 1
fi

# Load environment variables
export $(grep -v '^#' "$env_file" | xargs)

echo "Deploying application via $manifest_file with env $env_file..."

docker-compose -f "$manifest_file" up -d

echo "Deployment complete. Check services with: docker-compose ps"
