# Istio Traffic Management Demos

This repository contains comprehensive demonstrations of Istio service mesh traffic management capabilities, showcasing different deployment strategies and traffic control patterns in Kubernetes environments.

## Repository Structure

```
Traffic-Management/
├── flagger-canary-release/     # Automated canary deployments with Flagger
└── traffic-shifting/           # Manual traffic shifting demonstrations
```

## Demonstrations Overview

### 1. Traffic Shifting (`traffic-shifting/`)
**Purpose**: Manual traffic control and weighted routing between service versions

**Key Features**:
- Weighted traffic distribution (0/100, 20/80, 50/50, 100/0)
- A/B testing capabilities
- Blue-green deployment patterns
- Manual canary deployment control

**Technologies**:
- Istio VirtualService for traffic routing
- DestinationRule for load balancing
- Kubernetes Deployments (v1 and v2)
- React frontend with movie catalog backend

**Components**:
- Backend V1: Bollywood movies (TMDB API)
- Backend V2: Hollywood movies (TMDB API) 
- Frontend: React-based movie catalog UI
- Istio Gateway for external traffic

### 2. Flagger Canary Release (`flagger-canary-release/`)
**Purpose**: Automated progressive delivery with canary analysis

**Key Features**:
- Automated traffic shifting based on metrics
- Prometheus-based canary analysis
- Automatic rollback on failure detection
- Load testing integration
- Success rate and latency monitoring

**Technologies**:
- Flagger CRD for automated canary deployments
- Istio service mesh integration
- Prometheus metrics collection
- Kubernetes native resources

**Components**:
- Primary workload (stable version)
- Canary workload (new version)
- Movie frontend application
- Automated testing framework

## Metadata

### Repository Information
- **Domain**: DevOps and Cloud Technologies
- **Technology Stack**: Kubernetes, Istio Service Mesh
- **Focus Area**: Traffic Management and Progressive Delivery
- **Deployment Patterns**: Canary, Blue-Green, A/B Testing
- **Date Created**: 2025
- **Maintained By**: DevOps Engineering Team

### Prerequisites
- Kubernetes cluster with Istio service mesh installed
- kubectl configured for cluster access
- Prometheus and Grafana (for monitoring)
- Flagger operator (for automated canary demos)

### Use Cases
- **Development Teams**: Learn progressive deployment strategies
- **DevOps Engineers**: Implement traffic management patterns
- **SRE Teams**: Reduce deployment risks through gradual rollouts
- **Platform Engineers**: Build robust deployment pipelines

## Getting Started

Each demonstration includes:
- 📋 **Setup instructions** (`SETUP.md`)
- 🚀 **Deployment scripts** (`deploy.sh`)
- 🔬 **Testing scripts** (`test-*.sh`)
- 🧹 **Cleanup scripts** (`cleanup.sh`)
- 📖 **Detailed documentation** (`README.md`)

### Quick Start
1. Choose your demonstration:
   - For manual traffic control: `cd traffic-shifting/`
   - For automated canary: `cd flagger-canary-release/`

2. Follow the setup instructions in the respective `SETUP.md`

3. Run the deployment: `./deploy.sh`

4. Execute tests: `./test-*.sh`

5. Clean up resources: `./cleanup.sh`

## Architecture Patterns

### Traffic Shifting Pattern
```
Client → Istio Gateway → VirtualService → DestinationRule → Services (v1/v2)
```

### Flagger Canary Pattern  
```
Client → Istio Gateway → Flagger Canary → Auto-generated VirtualService → Services (primary/canary)
```

## Monitoring and Observability

Both demonstrations integrate with:
- **Prometheus**: Metrics collection and analysis
- **Grafana**: Visualization dashboards
- **Kiali**: Service mesh topology and traffic flow
- **Jaeger**: Distributed tracing (optional)

## Best Practices Demonstrated

- **Gradual Traffic Shifting**: Minimize deployment risk
- **Automated Rollback**: Quick recovery from failures  
- **Metrics-Based Decisions**: Data-driven deployment validation
- **Load Testing**: Validate performance under traffic
- **Infrastructure as Code**: Reproducible deployments

## Contributing

When adding new traffic management demonstrations:
1. Follow the established directory structure
2. Include comprehensive documentation
3. Provide setup, deployment, and cleanup scripts
4. Add monitoring and testing capabilities
5. Update this root README with new metadata

## Support

For questions or issues:
- Review individual demonstration README files
- Check Istio documentation for service mesh concepts
- Consult Flagger documentation for automated canary deployments
- Refer to Kubernetes documentation for cluster operations

---

**Last Updated**: June 2025  
**Istio Version Compatibility**: 1.20+  
**Kubernetes Version**: 1.28+
