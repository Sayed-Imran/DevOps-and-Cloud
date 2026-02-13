set -e 
export CTX_CLUSTER1="kind-cluster1"
export CTX_CLUSTER2="kind-cluster2"

# Install Istio on cluster1
istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml -y

# Install east-west gateway on cluster1
istioctl --context="${CTX_CLUSTER1}" install -y -f eastwest-gateway-cluster1.yaml

# Expose services on cluster1
kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f expose-services.yaml

# Export CA secrets from cluster1
kubectl get secrets --context="${CTX_CLUSTER1}" -n istio-system \
    istio-ca-secret -oyaml > istio-ca-secrets.yaml

# Create istio-system namespace and apply CA secrets on cluster2
kubectl create ns istio-system --context="${CTX_CLUSTER2}"
kubectl apply -f istio-ca-secrets.yaml --context="${CTX_CLUSTER2}"

# Install Istio on cluster2
istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml -y

# Install east-west gateway on cluster2
istioctl --context="${CTX_CLUSTER2}" install -y -f eastwest-gateway-cluster2.yaml

# Expose services on cluster2
kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f expose-services.yaml
