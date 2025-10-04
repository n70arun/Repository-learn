#!/bin/bash
set -e

# -----------------------------
# Configuration
# -----------------------------
METALLB_NAMESPACE="metallb-system"
METALLB_VERSION="v0.13.9"
IP_POOL_FILE="metallb-config.yaml"  # your IPAddressPool manifest

# -----------------------------
# 1️⃣ Cleanup existing MetalLB resources
# -----------------------------
echo "Cleaning up any existing MetalLB resources..."
kubectl delete namespace $METALLB_NAMESPACE --ignore-not-found=true

# -----------------------------
# 2️⃣ Create metallb-system namespace
# -----------------------------
echo "Creating namespace $METALLB_NAMESPACE..."
kubectl create namespace $METALLB_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# -----------------------------
# 3️⃣ Create memberlist secret
# -----------------------------
echo "Creating memberlist secret..."
kubectl get secret memberlist -n $METALLB_NAMESPACE >/dev/null 2>&1 || \
kubectl create secret generic memberlist \
  --namespace $METALLB_NAMESPACE \
  --from-literal=secretkey="$(openssl rand -base64 128)"

# -----------------------------
# 4️⃣ Apply MetalLB manifests
# -----------------------------
echo "Applying MetalLB core manifests..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/$METALLB_VERSION/config/manifests/metallb-native.yaml

# -----------------------------
# 5️⃣ Patch controller tolerations
# -----------------------------
echo "Patching controller to allow scheduling on control-plane node..."
kubectl patch deployment controller -n $METALLB_NAMESPACE --type='json' -p='[{"op":"add","path":"/spec/template/spec/tolerations","value":[{"key":"node-role.kubernetes.io/control-plane","operator":"Exists","effect":"NoSchedule"}]}]'

# --------------------------
# -----------------------------
# 6️⃣ Wait for MetalLB controller & speaker
# -----------------------------
echo "Waiting for MetalLB pods to be ready..."
kubectl wait --namespace $METALLB_NAMESPACE --for=condition=ready pod -l app=metallb --timeout=120s

# -----------------------------
# 7️⃣ Apply IP pool config
# -----------------------------
echo "Applying IP pool configuration..."
kubectl apply -f $IP_POOL_FILE

