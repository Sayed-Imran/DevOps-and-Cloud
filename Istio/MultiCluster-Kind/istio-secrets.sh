#!/bin/bash
set -e

# Get cluster control plane IP addresses
CLUSTER1_IP=$(docker inspect cluster1-control-plane --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
CLUSTER2_IP=$(docker inspect cluster2-control-plane --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')

echo "Cluster1 API Server IP: ${CLUSTER1_IP}"
echo "Cluster2 API Server IP: ${CLUSTER2_IP}"

# For cluster1 secret (to be applied on cluster2)
echo "Creating remote secret for cluster1..."
istioctl create-remote-secret \
  --context="${CTX_CLUSTER1}" \
  --name=cluster1 \
  --server=https://${CLUSTER1_IP}:6443 | \
  kubectl apply -f - --context="${CTX_CLUSTER2}"

# For cluster2 secret (to be applied on cluster1)
echo "Creating remote secret for cluster2..."
istioctl create-remote-secret \
  --context="${CTX_CLUSTER2}" \
  --name=cluster2 \
  --server=https://${CLUSTER2_IP}:6443 | \
  kubectl apply -f - --context="${CTX_CLUSTER1}"

echo "Remote secrets created successfully!"