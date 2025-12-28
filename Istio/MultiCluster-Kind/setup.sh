#!/bin/bash
set -e

echo "Creating Kind clusters..."
kind create cluster --config cluster1-config.yaml &
kind create cluster --config cluster2-config.yaml &
wait

echo "Installing MetalLB on cluster1..."
kubectl config use-context kind-cluster1
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml --config kind-cluster1
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s --config kind-cluster1
sleep 10
kubectl apply -f metallb-cluster1.yaml --config kind-cluster1

echo "Installing MetalLB on cluster2..."
kubectl config use-context kind-cluster2
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml --config kind-cluster2
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s --config kind-cluster2
sleep 10
kubectl apply -f metallb-cluster2.yaml --config kind-cluster2

echo "Setup complete!"
echo "Cluster1 MetalLB IP range: 172.17.255.1-172.17.255.100"
echo "Cluster2 MetalLB IP range: 172.17.255.101-172.17.255.200"
echo ""
echo "Both clusters are on the same Docker network (172.17.0.0/16)"
echo "LoadBalancer IPs from one cluster are accessible from pods in the other cluster"
