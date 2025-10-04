# Switch to your namespace
kubectl create namespace npm

# Create a secret (passwords only)
kubectl create secret generic npm-secrets \
  --from-env-file=/Users/arun/Desktop/npm.env \
  -n npm

# # Create a configmap (non-sensitive vars only)
# kubectl create configmap npm-config \
#   --from-env-file=/Users/arun/Desktop/npm.env \
#   -n npm
