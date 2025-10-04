#!/bin/bash

# Namespace
NAMESPACE=npm

# Apply Nginx Proxy Manager deployment
kubectl apply -f Ngnix-Proxy-Manager.yaml -n $NAMESPACE

# Apply PersistentVolumeClaims
kubectl apply -f persistant-volumes-claims.yaml -n $NAMESPACE

# Apply Services for NPM
kubectl apply -f Npm-services.yaml -n $NAMESPACE

# Start port-forward to Admin UI
#kubectl port-forward -n $NAMESPACE svc/npm-app 30081:81
