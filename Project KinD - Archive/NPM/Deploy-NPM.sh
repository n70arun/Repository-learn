#!/bin/bash

NS="npm"

kubectl get namespace $NS >/dev/null 2>&1 || kubectl create namespace $NS

# Namespace
NAMESPACE=$NS

# Apply PersistentVolumeClaims first
kubectl apply -f persistant-volumes-claims.yaml -n $NAMESPACE

# Wait for PVCs
kubectl wait --for=condition=Bound pvc/npm-data -n $NAMESPACE --timeout=60s
kubectl wait --for=condition=Bound pvc/npm-db -n $NAMESPACE --timeout=60s


# Apply Nginx Proxy Manager deployment
kubectl apply -f Ngnix-Proxy-Manager.yaml -n $NAMESPACE

# Wait for pods to be ready
kubectl wait --for=condition=Ready pod -l app=npm-app -n $NAMESPACE --timeout=120s
kubectl wait --for=condition=Ready pod -l app=npm-db -n $NAMESPACE --timeout=120s


# Apply Services for NPM
kubectl apply -f Npm-services.yaml -n $NAMESPACE

# Start port-forward to Admin UI
#kubectl port-forward -n $NAMESPACE svc/npm-app 30081:81


echo "Dont forget to publish secrets and config maps using the below command"
echo "/n"
echo 'cat /Users/arun/Desktop/*env | ssh n70arun@pandora "kubectl create secret generic npm-secrets --from-env-file=/dev/stdin -n npm --dry-run=client -o yaml | kubectl apply -f -"'
echo "/n"
echo 'cat /Users/arun/Desktop/*env | ssh n70arun@pandora "kubectl create configmap npm-config --from-env-file=/dev/stdin -n npm --dry-run=client -o yaml | kubectl apply -f -"'
echo "once done restart the Npm deployment using the below command"
echo "/n"
echo 'ssh n70arun@pandora "kubectl rollout restart deployment/npm-db -n npm && kubectl rollout restart deployment/npm-app -n npm"'
echo "/n"
echo "Restart Pods"
echo "/n"
echo 'kubectl rollout restart deployment npm-app -n npm
kubectl rollout restart deployment npm-db -n npm'
