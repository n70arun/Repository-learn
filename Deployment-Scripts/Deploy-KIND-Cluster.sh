#!/bin/bash
set -euo pipefail

CLUSTER_NAME="kind-cluster-pandora"
NETWORK_NAME="kind-net"
SUBNET_CIDR="172.20.0.0/16"
KIND_CONFIG="K8S-Config-1CP-2W.yaml"

# -----------------------------
# Cleanup if resources exist
# -----------------------------

# Delete cluster only if it exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "Deleting existing cluster: ${CLUSTER_NAME}..."
  kind delete cluster --name "${CLUSTER_NAME}"
  # Wait until cluster is fully removed
  while kind get clusters | grep -q "^${CLUSTER_NAME}$"; do
    echo "Waiting for cluster ${CLUSTER_NAME} to be deleted..."
    sleep 10
  done
fi

# Delete Docker network if it exists
if docker network ls --format '{{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
  echo "Removing existing Docker network: ${NETWORK_NAME}..."
  docker network rm "${NETWORK_NAME}"
  # Wait until network is gone
  while docker network ls --format '{{.Name}}' | grep -q "^${NETWORK_NAME}$"; do
    echo "Waiting for network ${NETWORK_NAME} to be removed..."
    sleep 2
  done
fi

# -----------------------------
# Create new network and cluster
# -----------------------------

#echo "Creating Docker network ${NETWORK_NAME}..."
#docker network create --driver=bridge --subnet="${SUBNET_CIDR}" "${NETWORK_NAME}"

echo "Creating kind cluster ${CLUSTER_NAME}..."
# KIND_EXPERIMENTAL_DOCKER_NETWORK="${NETWORK_NAME}" \
#   kind create cluster --name "${CLUSTER_NAME}" --config "${KIND_CONFIG}"

kind create cluster --name "${CLUSTER_NAME}" --config "${KIND_CONFIG}"

echo "✅ Cluster and network setup complete."
