#!/bin/bash
# Cleanup MetalLB from Kubernetes (KIND) cluster

set -e

echo "🚀 Starting MetalLB cleanup..."

# 1️⃣ Delete MetalLB namespace
echo "Deleting MetalLB namespace..."
kubectl delete namespace metallb-system --ignore-not-found

# 2️⃣ Delete MetalLB CRDs
echo "Deleting MetalLB CRDs..."
kubectl delete crd \
  addresspools.metallb.io \
  bfdprofiles.metallb.io \
  bgpadvertisements.metallb.io \
  bgppeers.metallb.io \
  communities.metallb.io \
  ipaddresspools.metallb.io \
  l2advertisements.metallb.io \
  --ignore-not-found

# 3️⃣ Delete leftover RBAC objects
echo "Deleting RBAC objects..."
kubectl delete clusterrole metallb-system:controller metallb-system:speaker --ignore-not-found
kubectl delete clusterrolebinding metallb-system:controller metallb-system:speaker --ignore-not-found
kubectl delete rolebinding -n metallb-system controller pod-lister --ignore-not-found
kubectl delete role -n metallb-system controller pod-
