# Multi-Cluster Kind Setup with MetalLB

This setup creates two Kind clusters with MetalLB configured for cross-cluster LoadBalancer IP accessibility.

## Architecture

- **Cluster 1**
  - Pod Subnet: 10.244.0.0/16
  - Service Subnet: 10.96.0.0/16
  - MetalLB IP Range: 172.17.255.1-172.17.255.100
  - Nodes: 1 control-plane + 2 workers

- **Cluster 2**
  - Pod Subnet: 10.245.0.0/16
  - Service Subnet: 10.97.0.0/16
  - MetalLB IP Range: 172.17.255.101-172.17.255.200
  - Nodes: 1 control-plane + 2 workers

Both clusters share the same Docker network (172.17.0.0/16), enabling pods from one cluster to access LoadBalancer IPs from the other cluster.

## Quick Setup

Run the automated setup script:

```bash
chmod +x setup.sh
./setup.sh
```

## Manual Setup

### 1. Create the clusters

```bash
kind create cluster --config cluster1-config.yaml
kind create cluster --config cluster2-config.yaml
```

### 2. Install MetalLB on cluster1

```bash
kubectl config use-context kind-cluster1
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s
kubectl apply -f metallb-cluster1.yaml
```

### 3. Install MetalLB on cluster2

```bash
kubectl config use-context kind-cluster2
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s
kubectl apply -f metallb-cluster2.yaml
```

## Verification

Test cross-cluster connectivity by creating a LoadBalancer service in one cluster and accessing it from a pod in the other cluster.

### Example: Create a service in cluster1

```bash
kubectl config use-context kind-cluster1
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=LoadBalancer --port=80
kubectl get svc nginx  # Note the EXTERNAL-IP
```

### Access from cluster2

```bash
kubectl config use-context kind-cluster2
kubectl run test --rm -it --image=busybox -- wget -O- <EXTERNAL-IP-from-cluster1>
```

## Cleanup

```bash
kind delete cluster --name cluster1
kind delete cluster --name cluster2
```

## Files

- `cluster1-config.yaml` - Kind configuration for cluster1
- `cluster2-config.yaml` - Kind configuration for cluster2
- `metallb-cluster1.yaml` - MetalLB IP pool configuration for cluster1
- `metallb-cluster2.yaml` - MetalLB IP pool configuration for cluster2
- `setup.sh` - Automated setup script
