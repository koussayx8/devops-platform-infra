# 🏗️ DevOps Platform Architecture

## Table of Contents

- [Overview](#overview)
- [Architecture Diagram](#architecture-diagram)
- [Infrastructure Layers](#infrastructure-layers)
- [Network Architecture](#network-architecture)
- [Security Architecture](#security-architecture)
- [High Availability Design](#high-availability-design)
- [Scalability Patterns](#scalability-patterns)
- [Monitoring & Observability](#monitoring--observability)
- [Disaster Recovery](#disaster-recovery)
- [Design Decisions](#design-decisions)
- [Technology Stack](#technology-stack)

## Overview

The DevOps Platform is designed as a **cloud-native, scalable, and highly available** infrastructure for hosting containerized applications on AWS. The architecture follows **industry best practices** for security, observability, and cost optimization.

### Core Principles

1. **Infrastructure as Code (IaC)**: All infrastructure defined and managed through Terraform
2. **GitOps**: Declarative continuous delivery using ArgoCD
3. **Cloud-Native**: Containerized workloads orchestrated by Kubernetes
4. **Security First**: Defense in depth with multiple security layers
5. **Cost Optimization**: Smart resource allocation and spot instances
6. **Observability**: Comprehensive monitoring and logging

## Architecture Diagram

### High-Level Architecture

```
                                    ┌──────────────────────────────────────┐
                                    │         AWS Cloud (Region)           │
                                    │                                      │
┌─────────────────┐                 │  ┌────────────────────────────────┐ │
│                 │                 │  │      VPC (10.0.0.0/16)         │ │
│   Developers    │                 │  │                                │ │
│   & CI/CD       │                 │  │  ┌──────────────────────────┐ │ │
│   Pipelines     │───Git Push────► │  │  │   Public Subnets         │ │ │
│                 │                 │  │  │   (10.0.1.0/24, .2.0/24) │ │ │
└─────────────────┘                 │  │  │                          │ │ │
                                    │  │  │  ┌─────────────────┐    │ │ │
┌─────────────────┐                 │  │  │  │   Internet      │    │ │ │
│                 │                 │  │  │  │   Gateway       │    │ │ │
│  End Users      │───HTTPS────────►│  │  │  └────────┬────────┘    │ │ │
│                 │                 │  │  │           │             │ │ │
└─────────────────┘                 │  │  │  ┌────────▼────────┐    │ │ │
                                    │  │  │  │ Application     │    │ │ │
                                    │  │  │  │ Load Balancer   │    │ │ │
                                    │  │  │  │     (ALB)       │    │ │ │
                                    │  │  │  └────────┬────────┘    │ │ │
                                    │  │  └───────────┼─────────────┘ │ │
                                    │  │              │               │ │
                                    │  │  ┌───────────▼─────────────┐ │ │
                                    │  │  │   Private Subnets       │ │ │
                                    │  │  │   (10.0.10.0/24,        │ │ │
                                    │  │  │    10.0.20.0/24)        │ │ │
                                    │  │  │                         │ │ │
                                    │  │  │  ┌───────────────────┐  │ │ │
                                    │  │  │  │   EKS Cluster     │  │ │ │
                                    │  │  │  │   Worker Nodes    │  │ │ │
                                    │  │  │  │                   │  │ │ │
                                    │  │  │  │ ┌───────────────┐ │  │ │ │
                                    │  │  │  │ │   Pods        │ │  │ │ │
                                    │  │  │  │ │ - Frontend    │ │  │ │ │
                                    │  │  │  │ │ - Backend API │ │  │ │ │
                                    │  │  │  │ │ - Database    │ │  │ │ │
                                    │  │  │  │ │ - ArgoCD      │ │  │ │ │
                                    │  │  │  │ │ - Prometheus  │ │  │ │ │
                                    │  │  │  │ │ - Grafana     │ │  │ │ │
                                    │  │  │  │ └───────────────┘ │  │ │ │
                                    │  │  │  └───────────────────┘  │ │ │
                                    │  │  │                         │ │ │
                                    │  │  │  ┌───────────────────┐  │ │ │
                                    │  │  │  │   NAT Gateway     │  │ │ │
                                    │  │  │  │   (Outbound)      │  │ │ │
                                    │  │  │  └───────────────────┘  │ │ │
                                    │  │  └─────────────────────────┘ │ │
                                    │  └────────────────────────────────┘ │
                                    │                                      │
                                    │  ┌────────────────────────────────┐ │
                                    │  │   Managed Services             │ │
                                    │  │                                │ │
                                    │  │  • EKS Control Plane           │ │
                                    │  │  • CloudWatch Logs             │ │
                                    │  │  • ECR (Container Registry)    │ │
                                    │  │  • S3 (Terraform State)        │ │
                                    │  │  • DynamoDB (State Lock)       │ │
                                    │  └────────────────────────────────┘ │
                                    └──────────────────────────────────────┘

                                    ┌──────────────────────────────────────┐
                                    │   External Services                  │
                                    │                                      │
                                    │  • GitHub (Git Repository)           │
                                    │  • Container Registry                │
                                    │  • CI/CD Pipeline (Jenkins)          │
                                    └──────────────────────────────────────┘
```

## Infrastructure Layers

### 1. Network Layer (VPC)

The foundation of our infrastructure is a custom VPC designed for security and scalability.

**Components:**

- **VPC CIDR**: 10.0.0.0/16 (65,536 IP addresses)
- **Public Subnets**: 2 subnets in different AZs (10.0.1.0/24, 10.0.2.0/24)
  - Host: Internet Gateway, NAT Gateway, ALB
  - Total: 512 IPs (256 per subnet)
- **Private Subnets**: 2 subnets in different AZs (10.0.10.0/24, 10.0.20.0/24)
  - Host: EKS worker nodes and pods
  - Total: 512 IPs (256 per subnet)

**Key Features:**

- **Internet Gateway**: Enables internet access for resources in public subnets
- **NAT Gateway**: Allows private subnet resources to access internet (outbound only)
- **Route Tables**: Separate routing for public and private subnets
- **VPC Flow Logs**: Network traffic logging for security analysis

**Subnet Tagging for EKS:**

```hcl
# Public subnets
"kubernetes.io/cluster/${cluster-name}" = "shared"
"kubernetes.io/role/elb" = "1"

# Private subnets
"kubernetes.io/cluster/${cluster-name}" = "shared"
"kubernetes.io/role/internal-elb" = "1"
```

### 2. Compute Layer (EKS)

Amazon EKS provides managed Kubernetes control plane and worker nodes.

**EKS Control Plane:**

- **Managed Service**: AWS handles master nodes, etcd, API server
- **High Availability**: Multi-AZ deployment automatically
- **Logging**: All control plane logs sent to CloudWatch
  - API Server logs
  - Audit logs
  - Authenticator logs
  - Controller Manager logs
  - Scheduler logs

**Worker Nodes (Managed Node Group):**

- **Instance Type**: m7i-flex.large
  - 2 vCPUs
  - 8 GB Memory
  - Up to 12.5 Gbps network
- **Capacity Type**: SPOT instances (90% cost savings)
- **Auto-scaling**: 1-4 nodes based on demand
- **AMI**: Amazon Linux 2 (AL2_x86_64)
- **Storage**: 20GB GP3 volumes per node

**Node Specifications:**

```yaml
Resources:
  CPU:
    Request: 300m per pod
    Limit: 500m per pod
  Memory:
    Request: 500Mi per pod
    Limit: 1Gi per pod
```

### 3. Application Layer

Three-tier application architecture:

**Frontend:**
- Technology: Angular/React
- Deployment: Nginx-based container
- Replicas: 1-3 (auto-scaling)
- Resources: 250m CPU, 256Mi Memory

**Backend API:**
- Technology: Spring Boot 3.x
- Language: Java 17
- Port: 8089
- Context Path: /api
- Replicas: 1-3 (auto-scaling)
- Resources: 500m CPU, 1Gi Memory
- Health Checks:
  - Liveness: /api/actuator/health
  - Readiness: /api/actuator/health

**Database:**
- Technology: MySQL 8.0
- Deployment: StatefulSet
- Storage: Persistent Volume (20GB)
- Replicas: 1 (single instance for dev)

### 4. GitOps Layer (ArgoCD)

Automated continuous delivery using GitOps principles.

**Components:**

- **ArgoCD Server**: Web UI and API server
- **Application Controller**: Monitors Git and synchronizes
- **Repo Server**: Interacts with Git repositories
- **Dex Server**: SSO and authentication
- **Redis**: Caching layer

**Deployment Model:**

```yaml
Application Flow:
  1. Developer commits to Git
  2. ArgoCD detects changes (auto-sync enabled)
  3. ArgoCD compares desired vs actual state
  4. ArgoCD applies changes to cluster
  5. Health checks validate deployment
  6. Self-heal reverts manual changes
```

**ArgoCD Projects:**

- **ski-station-project**: Main application project
  - Allowed repositories: GitHub organization repos
  - Allowed destinations: All namespaces
  - Allowed resources: All Kubernetes resources

### 5. Monitoring Layer

Comprehensive observability stack using Prometheus and Grafana.

**Prometheus:**
- **Function**: Metrics collection and alerting
- **Scrape Interval**: 30 seconds
- **Retention**: 15 days
- **Storage**: Persistent Volume (20GB)
- **Exporters**:
  - Node Exporter (system metrics)
  - kube-state-metrics (Kubernetes objects)
  - cAdvisor (container metrics)

**Grafana:**
- **Function**: Visualization and dashboards
- **Data Source**: Prometheus
- **Dashboards**:
  - Kubernetes cluster monitoring
  - Node resource usage
  - Pod metrics
  - Application metrics (Spring Boot)
  - ArgoCD metrics

**ServiceMonitor:**
- Automatic discovery of services
- Prometheus configuration via CRDs
- Monitors: API endpoints with /actuator/prometheus

## Network Architecture

### Traffic Flow

#### Ingress Traffic (User → Application)

```
Internet
   │
   ▼
Internet Gateway
   │
   ▼
Application Load Balancer (Public Subnet)
   │
   ├──► Path: / ──────────► Frontend Service (Port 80)
   │                            │
   │                            ▼
   │                       Frontend Pods (Private Subnet)
   │
   └──► Path: /api ───────► API Service (Port 8089)
                                │
                                ▼
                           API Pods (Private Subnet)
                                │
                                ▼
                           MySQL Service (Port 3306)
                                │
                                ▼
                           MySQL Pod (Private Subnet)
```

#### Egress Traffic (Application → Internet)

```
Application Pods (Private Subnet)
   │
   ▼
NAT Gateway (Public Subnet)
   │
   ▼
Internet Gateway
   │
   ▼
Internet
```

### DNS Resolution

- **Internal**: CoreDNS (cluster.local)
- **External**: Route 53 (optional)
- **Service Discovery**: Kubernetes DNS

### Load Balancing

**Application Load Balancer (ALB):**
- Layer 7 (HTTP/HTTPS) load balancing
- Path-based routing
- Health checks
- SSL/TLS termination (optional)
- Access logs to S3

**Internal Service Load Balancing:**
- ClusterIP services for internal communication
- iptables-based load balancing (kube-proxy)

## Security Architecture

### Defense in Depth

Multiple layers of security controls:

#### 1. Network Security

**VPC Isolation:**
- Private subnets for compute resources
- No direct internet access to worker nodes
- NAT Gateway for controlled egress

**Security Groups:**

```hcl
# EKS Cluster Security Group
Ingress:
  - From: Worker nodes
  - Port: 443 (API Server)
  
# Worker Node Security Group
Ingress:
  - From: Cluster security group
  - Port: 1025-65535
  - From: Self (node-to-node communication)

Egress:
  - To: 0.0.0.0/0 (All traffic)
```

**Network Policies:**
- Pod-to-pod communication rules
- Namespace isolation
- Default deny policies

#### 2. IAM Security

**IRSA (IAM Roles for Service Accounts):**
- Fine-grained permissions for pods
- No need for node-level IAM permissions
- OIDC provider integration

**IAM Roles:**
- EKS Cluster Role
- EKS Node Group Role
- AWS Load Balancer Controller Role
- CloudWatch Logs Role

#### 3. Application Security

**Container Security:**
- Non-root user execution
- Read-only root filesystem
- No privileged containers
- Resource limits enforced

**Secrets Management:**
- Kubernetes Secrets
- External secrets operator (optional)
- AWS Secrets Manager integration (future)

#### 4. Access Control

**RBAC (Role-Based Access Control):**

```yaml
Roles:
  - Developer: View and sync applications
  - DevOps: Full cluster access
  - Viewer: Read-only access
```

**Authentication:**
- AWS IAM authentication
- kubectl auth via aws-iam-authenticator
- ArgoCD SSO (optional)

### Security Best Practices

✅ **Implemented:**
- VPC with private subnets
- Security groups with least privilege
- IAM roles with minimal permissions
- IRSA for pod-level permissions
- Encrypted EBS volumes
- VPC Flow Logs enabled
- CloudWatch logging enabled

🔄 **Planned:**
- AWS WAF for ALB
- GuardDuty threat detection
- AWS Secrets Manager
- Certificate Manager for SSL/TLS
- Security scanning with Trivy
- OPA (Open Policy Agent) for policy enforcement

## High Availability Design

### Multi-AZ Deployment

**Availability Zones:**
- Minimum: 2 AZs (us-east-1a, us-east-1b)
- Worker nodes distributed across AZs
- Subnets in each AZ

**Fault Tolerance:**

```yaml
Component Availability:
  EKS Control Plane: 99.95% SLA (AWS managed)
  Worker Nodes: Auto-scaling across AZs
  Applications: Multiple replicas across nodes
  Database: Single instance (dev), Multi-AZ (prod)
```

### Auto-Recovery

**Node Failures:**
- Auto Scaling Group replaces unhealthy nodes
- Pods rescheduled automatically
- Health checks detect failures

**Pod Failures:**
- Kubernetes restarts failed containers
- Liveness probes detect issues
- Readiness probes prevent traffic to unhealthy pods

### Backup Strategy

**Application Data:**
- MySQL: Persistent volumes with snapshots
- Configuration: Stored in Git (GitOps)
- Secrets: Kubernetes etcd (backed up by AWS)

**Infrastructure:**
- Terraform state in S3 with versioning
- ArgoCD configuration in Git
- Disaster recovery runbooks

## Scalability Patterns

### Horizontal Scaling

**Pod Auto-Scaling (HPA):**

```yaml
Targets:
  - Frontend: 1-5 replicas based on CPU
  - API: 1-5 replicas based on CPU/Memory
  - Scale up: CPU > 70%
  - Scale down: CPU < 30%
```

**Cluster Auto-Scaling:**

```yaml
Node Group:
  Min: 1 node
  Desired: 2 nodes
  Max: 4 nodes
  
Scaling Triggers:
  - Scale up: Pods pending due to insufficient resources
  - Scale down: Node utilization < 50% for 10 minutes
```

### Vertical Scaling

**Resource Management:**
- Requests guarantee minimum resources
- Limits prevent resource exhaustion
- QoS classes: Guaranteed, Burstable, BestEffort

### Database Scaling

**Current (Dev):**
- Single MySQL instance
- 20GB storage

**Future (Production):**
- Amazon RDS with Multi-AZ
- Read replicas for scaling reads
- Connection pooling

## Monitoring & Observability

### Metrics Collection

**Prometheus Metrics:**

```yaml
Infrastructure Metrics:
  - Node CPU, Memory, Disk, Network
  - Pod resource usage
  - Cluster capacity and utilization
  
Application Metrics:
  - HTTP request rate
  - Response times (p50, p95, p99)
  - Error rates
  - JVM metrics (heap, GC, threads)
  
Kubernetes Metrics:
  - Deployment status
  - Pod restarts
  - Node conditions
  - Resource quotas
```

### Logging

**CloudWatch Logs:**
- EKS control plane logs
- Application stdout/stderr
- VPC Flow Logs

**Log Aggregation:**
- Fluent Bit (future)
- CloudWatch Logs Insights for queries

### Alerting

**Alert Rules:**
- Node down > 5 minutes
- Pod restart count > 5
- High CPU/Memory usage
- API error rate > 1%
- Disk usage > 85%

**Notification Channels:**
- Slack webhooks
- Email
- PagerDuty (on-call)

### Tracing

**Distributed Tracing (Future):**
- AWS X-Ray integration
- Jaeger for trace visualization
- OpenTelemetry instrumentation

## Disaster Recovery

### RTO & RPO

**Recovery Objectives:**

| Environment | RTO (Recovery Time Objective) | RPO (Recovery Point Objective) |
|-------------|------------------------------|--------------------------------|
| Development | 4 hours | 24 hours |
| Staging | 2 hours | 12 hours |
| Production | 1 hour | 1 hour |

### Backup Strategy

**Infrastructure:**
- Terraform state versioned in S3
- Automated daily snapshots
- Multi-region replication (optional)

**Application Data:**
- MySQL: Automated snapshots every 6 hours
- Persistent volumes: EBS snapshots
- Retention: 7 days (dev), 30 days (prod)

**Configuration:**
- Git repository (single source of truth)
- ArgoCD configuration
- Kubernetes manifests

### Recovery Procedures

**Scenario 1: Single Node Failure**
- Auto-scaling replaces node (5-10 minutes)
- Pods rescheduled automatically
- No manual intervention required

**Scenario 2: Availability Zone Failure**
- Traffic routed to healthy AZ
- Scale up nodes in remaining AZ
- Applications continue running

**Scenario 3: Complete Region Failure**
1. Provision infrastructure in backup region (30 minutes)
2. Restore database from snapshot (15 minutes)
3. Deploy applications via ArgoCD (10 minutes)
4. Update DNS to new region (5 minutes)
5. Total RTO: ~1 hour

## Design Decisions

### Why AWS EKS?

**Pros:**
✅ Managed control plane (reduced operational overhead)
✅ Native AWS integration (IAM, VPC, ALB, CloudWatch)
✅ Kubernetes version upgrades managed by AWS
✅ High availability built-in
✅ CNCF certified Kubernetes

**Cons:**
❌ Control plane costs ($73/month)
❌ Less control over control plane
❌ AWS-specific features may cause lock-in

**Alternatives Considered:**
- Self-managed Kubernetes (rejected: high operational overhead)
- ECS (rejected: less flexibility, not Kubernetes)
- GKE/AKS (rejected: multi-cloud strategy not required)

### Why Spot Instances?

**Pros:**
✅ Up to 90% cost savings
✅ Good for stateless workloads
✅ Auto Scaling Group handles interruptions

**Cons:**
❌ Can be interrupted with 2-minute notice
❌ Not suitable for stateful workloads without proper handling

**Mitigation:**
- Multiple AZs for redundancy
- Graceful shutdown handling
- Pod Disruption Budgets
- Mix with On-Demand instances (production)

### Why GitOps (ArgoCD)?

**Pros:**
✅ Git as single source of truth
✅ Declarative infrastructure
✅ Audit trail of all changes
✅ Easy rollbacks
✅ Automated synchronization
✅ Self-healing capabilities

**Cons:**
❌ Learning curve for teams
❌ Additional infrastructure component
❌ Potential sync delays (3-minute polling)

**Alternatives Considered:**
- FluxCD (rejected: ArgoCD has better UI)
- Jenkins X (rejected: too opinionated)
- Manual kubectl apply (rejected: not scalable)

### Why Single NAT Gateway?

**Decision:** Single NAT Gateway for dev/staging, multi-NAT for production

**Pros:**
✅ Cost savings (~$32/month)
✅ Sufficient for dev/staging traffic

**Cons:**
❌ Single point of failure
❌ Limited bandwidth

**Production Recommendation:**
- Use one NAT Gateway per AZ for HA
- Total cost increase: 2x ($64/month)

### Why Prometheus & Grafana?

**Pros:**
✅ Industry-standard monitoring
✅ Native Kubernetes integration
✅ Pull-based metrics (better for dynamic environments)
✅ Powerful query language (PromQL)
✅ Rich visualization with Grafana

**Alternatives Considered:**
- CloudWatch (rejected: limited Kubernetes metrics)
- Datadog (rejected: high costs)
- New Relic (rejected: vendor lock-in)

## Technology Stack

### Infrastructure

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| IaC | Terraform | 1.0+ | Infrastructure provisioning |
| Cloud Provider | AWS | - | Cloud infrastructure |
| Container Orchestration | Kubernetes (EKS) | 1.28 | Container management |
| GitOps | ArgoCD | 2.8.4 | Continuous delivery |
| Load Balancer | AWS ALB | - | Layer 7 load balancing |

### Networking

| Component | Technology | Purpose |
|-----------|-----------|---------|
| VPC | AWS VPC | Network isolation |
| CNI | AWS VPC CNI | Pod networking |
| DNS | CoreDNS | Service discovery |
| Ingress | ALB Ingress Controller | External access |

### Monitoring & Logging

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Metrics | Prometheus | 2.45+ | Metrics collection |
| Visualization | Grafana | 10.0+ | Dashboards |
| Logging | CloudWatch Logs | - | Log aggregation |
| Tracing | AWS X-Ray | - | Distributed tracing |

### Application Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Backend | Spring Boot | 3.x | REST API |
| Frontend | Angular/React | - | Web UI |
| Database | MySQL | 8.0 | Data persistence |
| Container Runtime | containerd | - | Container execution |

### Security

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Authentication | IAM / OIDC | Identity management |
| Authorization | RBAC | Access control |
| Secrets | Kubernetes Secrets | Sensitive data |
| Network Security | Security Groups | Firewall rules |
| Image Registry | Amazon ECR | Container images |

## Conclusion

This architecture provides a **robust, scalable, and cost-effective** platform for running containerized applications on AWS. The design balances:

- **Reliability**: Multi-AZ deployment, auto-scaling, self-healing
- **Security**: Defense in depth, least privilege access
- **Observability**: Comprehensive monitoring and logging
- **Cost**: Optimized resource usage, spot instances
- **Maintainability**: Infrastructure as Code, GitOps automation

### Next Steps

**Short-term Improvements:**
- [ ] Implement HPA for auto-scaling
- [ ] Add Cluster Autoscaler
- [ ] Configure custom Grafana dashboards
- [ ] Set up alerting rules

**Medium-term Improvements:**
- [ ] Multi-region deployment
- [ ] Amazon RDS for database
- [ ] AWS WAF for security
- [ ] Certificate Manager for SSL/TLS

**Long-term Improvements:**
- [ ] Service mesh (Istio/Linkerd)
- [ ] Advanced monitoring (Datadog/New Relic)
- [ ] Chaos engineering
- [ ] Multi-cloud strategy

---

**Document Version:** 1.0  
**Last Updated:** October 2, 2025  
**Author:** Koussay  
**Status:** Active