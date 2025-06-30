# Istio Service Mesh Demonstrations

This repository contains comprehensive demonstrations of Istio service mesh capabilities including security, traffic management, and external VM integration for Kubernetes environments.

## Repository Structure

```
Istio/
├── External Auth/              # External authorization with custom auth server
├── External-VM/               # External VM integration with Istio mesh
├── JWT Auth/                  # JWT-based authentication and authorization
└── Traffic-Management/        # Traffic routing and deployment strategies
    ├── flagger-canary-release/  # Automated canary deployments
    └── traffic-shifting/        # Manual traffic shifting demos
```

## Demonstrations Overview

### 1. External Auth (`External Auth/`)
**Purpose**: Demonstrate external authorization using custom authorization servers

**Key Features**:
- Custom external authorization server implementation
- Role-based access control (admin/anonymous)
- FastAPI-based authorization service
- Istio AuthorizationPolicy with CUSTOM action

**Components**:
- **API Service**: FastAPI application with item management endpoints
- **External Auth Server**: Custom authorization server for role validation
- **Authorization Policy**: Istio configuration for external authorization
- **Deployment Configs**: Kubernetes manifests for both services

**Technologies**:
- FastAPI (Python)
- Istio AuthorizationPolicy
- Custom authorization provider
- Kubernetes Deployments

### 2. External-VM (`External-VM/`)
**Purpose**: Integration of external virtual machines with Istio service mesh

**Key Features**:
- External VM registration with Istio mesh
- East-west gateway configuration
- Workload entry auto-registration
- Health checks for external workloads
- Service-to-service communication across VM and K8s

**Components**:
- **Workload Group**: Configuration for external VM registration
- **East-West Gateway**: Gateway for cross-cluster communication
- **Istio Gateway**: Configuration for external traffic
- **Setup Documentation**: Comprehensive guide for VM integration

**Technologies**:
- Istio WorkloadGroup
- Istio Gateway (East-West)
- External VM configuration
- Istio sidecar proxy

### 3. JWT Auth (`JWT Auth/`)
**Purpose**: JSON Web Token-based authentication and authorization

**Key Features**:
- JWT token validation
- Request authentication policies
- Authorization policies based on JWT claims
- Template-based configuration generation
- Automated policy deployment

**Components**:
- **API Service**: FastAPI application with JWT protection
- **Template Generator**: Python script for generating Istio policies
- **Authentication Templates**: Istio RequestAuthentication and AuthorizationPolicy
- **Gateway Templates**: Istio Gateway and VirtualService configurations

**Technologies**:
- JWT (JSON Web Tokens)
- Istio RequestAuthentication
- Istio AuthorizationPolicy
- FastAPI (Python)
- Template-based configuration

### 4. Traffic-Management (`Traffic-Management/`)
**Purpose**: Comprehensive traffic routing and deployment strategy demonstrations

#### 4.1 Flagger Canary Release (`flagger-canary-release/`)
**Purpose**: Automated progressive delivery with canary analysis

**Key Features**:
- Automated traffic shifting based on metrics
- Prometheus-based canary analysis
- Automatic rollback on failure detection
- Load testing integration
- Success rate and latency monitoring

**Components**:
- **Flagger CRD**: Automated canary deployment configuration
- **Backend/Frontend**: Movie catalog application (sample workload)
- **Canary Configuration**: Progressive delivery settings
- **Monitoring**: Prometheus metrics integration

**Technologies**:
- Flagger CRD
- Istio VirtualService (auto-generated)
- Prometheus metrics
- Kubernetes Deployments

#### 4.2 Traffic Shifting (`traffic-shifting/`)
**Purpose**: Manual traffic control and weighted routing between service versions

**Key Features**:
- Weighted traffic distribution (0/100, 20/80, 50/50, 100/0)
- A/B testing capabilities
- Blue-green deployment patterns
- Manual canary deployment control

**Components**:
- **Backend V1**: Bollywood movies service (TMDB API)
- **Backend V2**: Hollywood movies service (TMDB API)
- **Frontend**: React-based movie catalog UI
- **Traffic Rules**: Multiple VirtualService configurations for different traffic splits
- **Deployment Scripts**: Automated deployment and testing scripts

**Technologies**:
- Istio VirtualService
- Istio DestinationRule
- React Frontend
- Python Backend (FastAPI)
- TMDB API integration

## Quick Start Guide

Each demonstration includes:
- **README.md**: Detailed setup and usage instructions
- **Deployment Scripts**: Automated deployment (`deploy.sh`)
- **Cleanup Scripts**: Environment cleanup (`cleanup.sh`)
- **Test Scripts**: Validation and testing utilities
- **Configuration Files**: All necessary Kubernetes and Istio manifests

## Prerequisites

- Kubernetes cluster (1.20+)
- Istio installed (1.19+)
- kubectl configured
- Docker (for building custom images)
- Python 3.8+ (for FastAPI applications)

## Common Technologies Used

- **Istio Service Mesh**: Traffic management, security, and observability
- **FastAPI**: Python web framework for API services
- **React**: Frontend user interface
- **Kubernetes**: Container orchestration
- **Prometheus**: Metrics collection and monitoring
- **Flagger**: Progressive delivery automation
- **Docker**: Container packaging

## Architecture Patterns Demonstrated

1. **External Authorization**: Custom authorization servers with Istio
2. **External Service Integration**: VM-to-mesh connectivity
3. **JWT Authentication**: Token-based security
4. **Progressive Delivery**: Automated canary deployments
5. **Traffic Splitting**: Manual traffic control strategies
6. **Service Mesh Security**: Authentication and authorization policies
7. **Cross-Cluster Communication**: East-west gateway patterns

## Author

**Sayed Imran** - DevOps and Cloud Engineer

For detailed instructions on each demonstration, please refer to the respective README.md files in each directory.