# Flagger Canary Release Demo

This demo showcases automated canary deployments using Flagger with Istio service mesh. Flagger automates the promotion of canary deployments using Istio traffic shifting and Prometheus metrics for canary analysis.

## Overview

Flagger is a progressive delivery tool that automates the release process for applications running on Kubernetes. It reduces the risk of introducing a new software version in production by gradually shifting traffic to the canary while measuring metrics and running conformance tests.

This demo features:
- **Automated Canary Analysis**: Progressive traffic shifting based on success metrics
- **Automated Rollback**: Automatic rollback on failure detection
- **Load Testing**: Automated load testing during canary analysis
- **Prometheus Metrics**: Real-time monitoring of success rates and latency
- **Istio Integration**: Seamless integration with Istio service mesh

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│                 │    │                  │    │                 │
│   Istio Gateway │────┤   Flagger CRD    │────┤  VirtualService │
│                 │    │     (Canary)     │    │   (Generated)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    ▼                       ▼
            ┌───────────────┐       ┌───────────────┐
            │   Primary     │       │    Canary     │
            │  (Stable)     │       │  (New Version)│
            │   Workload    │       │   Workload    │
            └───────────────┘       └───────────────┘
                    │                       │
                    └───────────┬───────────┘
                                │
                        ┌───────────────┐
                        │   Frontend    │
                        │  (Movie UI)   │
                        │               │
                        └───────────────┘
```

## Components

### 1. Applications
- **Sample Workload**: A simple web application that can be updated with different versions
- **Movie Frontend**: React-based UI to interact with the backend
- **Movie Backend**: Movie catalog service (used as the canary target)

### 2. Flagger Resources
- **Canary CRD**: Defines the canary analysis configuration
- **LoadTester**: Generates traffic during canary analysis
- **Prometheus**: Monitors success rates and request duration

### 3. Kubernetes Resources
- **Deployment**: The target deployment for canary releases
- **Service**: Kubernetes service (managed by Flagger)
- **Gateway**: Istio gateway for external access
- **VirtualService**: Traffic routing (managed by Flagger)

## Prerequisites

1. **Kubernetes cluster** with Istio installed
2. **Flagger** installed in the cluster:
   ```bash
   # Add Flagger Helm repository
   helm repo add flagger https://flagger.app
   
   # Install Flagger CRDs
   kubectl apply -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/crd.yaml
   
   # Install Flagger for Istio
   helm upgrade -i flagger flagger/flagger \
     --namespace=istio-system \
     --set crd.create=false \
     --set meshProvider=istio \
     --set metricsServer=http://prometheus:9090
   ```

3. **Flagger Load Tester**:
   ```bash
   kubectl apply -k https://github.com/fluxcd/flagger//kustomize/tester?ref=main
   ```

4. **Prometheus** (for metrics collection):
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml
   ```

5. **Istio injection enabled**:
   ```bash
   kubectl label namespace default istio-injection=enabled
   ```

6. **kubectl**: Configured to access your cluster

## Quick Start

### Option 1: Automated Script (Recommended)
```bash
chmod +x deploy.sh
./deploy.sh
```

The script provides an interactive menu to:
- Deploy all resources including Flagger dependencies
- Initialize the canary deployment
- Trigger canary releases with new versions
- Monitor canary analysis progress
- Clean up resources

### Option 2: Manual Deployment

1. **Deploy the application:**
   ```bash
   kubectl apply -f backend.yaml
   kubectl apply -f frontend.yaml
   kubectl apply -f gateway.yaml
   ```

2. **Wait for deployment to be ready:**
   ```bash
   kubectl wait --for=condition=available --timeout=300s deployment/sample-workload
   kubectl wait --for=condition=available --timeout=300s deployment/movie-frontend
   ```

3. **Initialize Flagger canary:**
   ```bash
   kubectl apply -f canary.yaml
   ```

4. **Wait for Flagger to initialize:**
   ```bash
   kubectl wait --for=condition=promoted --timeout=300s canary/canary-release
   ```

## Triggering a Canary Release

### Scenario 1: Update Application Version
```bash
# Update the deployment with a new image version
kubectl set image deployment/sample-workload \
  sample-workload=sayedimran/istio-sample-workload:v2.0.0
```

### Scenario 2: Update Configuration
```bash
# Update environment variables
kubectl patch deployment sample-workload -p='{"spec":{"template":{"spec":{"containers":[{"name":"sample-workload","env":[{"name":"BG_COLOR","value":"green"},{"name":"SECONDARY_COLOR","value":"yellow"}]}]}}}}'
```

## Monitoring Canary Progress

### Watch Canary Status
```bash
# Watch canary analysis progress
kubectl get canary canary-release -w

# Get detailed canary status
kubectl describe canary canary-release

# Check Flagger events
kubectl get events --field-selector involvedObject.name=canary-release
```

### View Traffic Distribution
```bash
# Check current VirtualService configuration
kubectl get virtualservice sample-workload -o yaml

# Monitor pods
kubectl get pods -l app=sample-workload

# Check primary and canary services
kubectl get svc -l app=sample-workload
```

### Access Application
```bash
# Get ingress gateway URL
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

# Access the application
curl http://$GATEWAY_URL
# or open in browser
open http://$GATEWAY_URL
```

## Canary Analysis Configuration

The canary analysis is configured with the following parameters:

- **Interval**: 1 minute between analysis checks
- **Threshold**: 10 failed checks before rollback
- **Max Weight**: 50% maximum traffic to canary
- **Step Weight**: 10% traffic increment per successful check
- **Success Rate**: Minimum 99% success rate required
- **Request Duration**: Maximum 500ms average response time

### Metrics Monitored
1. **Request Success Rate**: HTTP 2xx responses / total requests
2. **Request Duration**: Average response time in milliseconds

### Webhooks
1. **Pre-rollout Test**: Validates canary before traffic shifting
2. **Load Test**: Generates consistent traffic during analysis

## Canary Lifecycle

1. **Initialization**: Flagger creates primary deployment and services
2. **Trigger**: Deployment update detected
3. **Canary Creation**: New version deployed as canary
4. **Pre-rollout**: Acceptance tests run against canary
5. **Traffic Shifting**: Gradual traffic increase (10% → 20% → 30% → 40% → 50%)
6. **Analysis**: Metrics checked at each step (1-minute intervals)
7. **Promotion**: If successful, canary becomes primary
8. **Rollback**: If failed, traffic returns to primary and canary is scaled down

## Observability

### Flagger Metrics Dashboard
```bash
# If Grafana is installed
istioctl dashboard grafana
# Navigate to Flagger dashboard
```

### Application Logs
```bash
# Check primary workload logs
kubectl logs -f deployment/sample-workload-primary

# Check canary workload logs (during analysis)
kubectl logs -f deployment/sample-workload

# Check Flagger operator logs
kubectl logs -f deployment/flagger -n istio-system
```

### Istio Observability
```bash
# Access Kiali dashboard
istioctl dashboard kiali

# Access Jaeger tracing
istioctl dashboard jaeger
```

## Troubleshooting

### Common Issues

1. **Canary stuck in initialization**:
   ```bash
   # Check Flagger logs
   kubectl logs -f deployment/flagger -n istio-system
   
   # Verify Prometheus connectivity
   kubectl exec -it deployment/flagger -n istio-system -- \
     wget -q -O- http://prometheus.istio-system:9090/api/v1/query?query=up
   ```

2. **Canary analysis failing**:
   ```bash
   # Check metrics manually
   kubectl port-forward -n istio-system svc/prometheus 9090:9090
   # Visit http://localhost:9090 and query istio metrics
   
   # Check load tester
   kubectl logs -f deployment/flagger-loadtester -n test
   ```

3. **Traffic not shifting**:
   ```bash
   # Verify VirtualService updates
   kubectl get virtualservice sample-workload -o yaml
   
   # Check Istio proxy configuration
   istioctl proxy-config routes deployment/sample-workload
   ```

### Cleanup

```bash
# Delete canary (this will also clean up generated resources)
kubectl delete canary canary-release

# Delete application
kubectl delete -f backend.yaml
kubectl delete -f frontend.yaml
kubectl delete -f gateway.yaml

# Delete namespace (if using dedicated namespace)
kubectl delete namespace canary-demo
```

## Advanced Configuration

### Custom Metrics
You can extend the canary analysis with custom Prometheus queries:

```yaml
metrics:
- name: "404-errors"
  thresholdRange:
    max: 5
  query: |
    sum(rate(
      istio_requests_total{
        destination_service_name="sample-workload",
        response_code="404"
      }[1m]
    ))
```

### Header-Based Testing
Enable testing with specific headers:

```yaml
analysis:
  # ... other configuration
  match:
    - headers:
        x-canary:
          exact: "true"
```

### Blue-Green Deployment
Switch to blue-green deployment mode:

```yaml
analysis:
  # Skip traffic shifting, promote directly after validation
  stepWeight: 100
  maxWeight: 100
```

## Resources

- [Flagger Documentation](https://flagger.app/)
- [Istio Traffic Management](https://istio.io/latest/docs/concepts/traffic-management/)
- [Progressive Delivery](https://argoproj.github.io/rollouts/)
- [Canary Deployments Best Practices](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments)
