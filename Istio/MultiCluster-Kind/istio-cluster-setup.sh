set -e 
istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml -y
cd /home/imran/istio-1.25.2

samples/multicluster/gen-eastwest-gateway.sh \
    --network network1 | \
    istioctl --context="${CTX_CLUSTER1}" install -y -f -

kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
    samples/multicluster/expose-services.yaml

kubectl get secrets --context="${CTX_CLUSTER1}"  -n istio-system \
istio-ca-secret -oyaml > istio-ca-secrets.yaml

kubectl create ns istio-system --context $CTX_CLUSTER2
kubectl apply -f istio-ca-secrets.yaml --context $CTX_CLUSTER2

cd /home/imran/projects/kubernetes/DevOps-and-Cloud/Istio/MultiCluster-Kind

istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml -y
cd /home/imran/istio-1.25.2
samples/multicluster/gen-eastwest-gateway.sh \
    --network network2 | \
    istioctl --context="${CTX_CLUSTER2}" install -y -f -

kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
