# 📘 Deployment Guide - DevOps Platform Infrastructure

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Pre-Deployment Checklist](#pre-deployment-checklist)
- [Step 1: AWS Setup](#step-1-aws-setup)
- [Step 2: Configure Terraform](#step-2-configure-terraform)
- [Step 3: Deploy Infrastructure](#step-3-deploy-infrastructure)
- [Step 4: Configure kubectl](#step-4-configure-kubectl)
- [Step 5: Install AWS Load Balancer Controller](#step-5-install-aws-load-balancer-controller)
- [Step 6: Deploy ArgoCD](#step-6-deploy-argocd)
- [Step 7: Deploy Applications](#step-7-deploy-applications)
- [Step 8: Verification](#step-8-verification)
- [Post-Deployment Tasks](#post-deployment-tasks)
- [Environment-Specific Configurations](#environment-specific-configurations)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

## Overview

This guide provides **step-by-step instructions** for deploying the complete DevOps Platform Infrastructure on AWS. The deployment process takes approximately **45-60 minutes**.

### Deployment Timeline

```
┌─────────────────────────────────────────────────────────────────┐
│                    Deployment Timeline                          │
├─────────────────────────────────────────────────────────────────┤
│ Step 1: AWS Setup                        │ 10 min              │
│ Step 2: Configure Terraform              │ 5 min               │
│ Step 3: Deploy Infrastructure            │ 15-20 min           │
│ Step 4: Configure kubectl                │ 2 min               │
│ Step 5: Install ALB Controller           │ 5 min               │
│ Step 6: Deploy ArgoCD                    │ 10 min              │
│ Step 7: Deploy Applications              │ 5 min               │
│ Step 8: Verification                     │ 5 min               │
├─────────────────────────────────────────────────────────────────┤
│ Total Time                               │ 45-60 min           │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Required Tools

Ensure all tools are installed and accessible from your terminal:

```bash
# Check Terraform
terraform version
# Expected: Terraform v1.0.0 or higher

# Check AWS CLI
aws --version
# Expected: aws-cli/2.x.x or higher

# Check kubectl
kubectl version --client
# Expected: v1.28.0 or higher

# Check helm
helm version
# Expected: v3.x.x or higher

# Check git
git --version
# Expected: git version 2.x.x or higher
```

### AWS Requirements

- **AWS Account**: Active account with billing enabled
- **IAM User/Role**: With administrator access or specific permissions:
  - VPC: Full access
  - EKS: Full access
  - EC2: Full access
  - IAM: Create roles and policies
  - CloudWatch: Full access
  - S3: Create and manage buckets
  - DynamoDB: Create and manage tables

### Knowledge Requirements

Basic understanding of:
- AWS services (VPC, EKS, IAM)
- Kubernetes concepts
- Terraform
- Git and GitOps principles

## Pre-Deployment Checklist

Before starting deployment, complete this checklist:

- [ ] AWS account created and active
- [ ] AWS CLI configured with credentials
- [ ] All required tools installed
- [ ] GitHub repository access
- [ ] S3 bucket name decided (must be globally unique)
- [ ] AWS region selected (default: us-east-1)
- [ ] Environment name decided (dev/staging/prod)
- [ ] Budget and cost limits reviewed

## Step 1: AWS Setup

### 1.1 Configure AWS CLI

```bash
# Configure AWS credentials
aws configure

# You'll be prompted for:
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "AIDXXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

### 1.2 Create S3 Bucket for Terraform State

```bash
# Set variables
export AWS_REGION="us-east-1"
export BUCKET_NAME="koussayx8-devops-terraform-state"  # Change to your unique name
export DYNAMODB_TABLE="terraform-state-locks"

# Create S3 bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $AWS_REGION

# Enable versioning (important for state history)
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Verify bucket creation
aws s3 ls | grep $BUCKET_NAME
```

### 1.3 Create DynamoDB Table for State Locking

```bash
# Create DynamoDB table
aws dynamodb create-table \
  --table-name $DYNAMODB_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $AWS_REGION

# Wait for table to be active
aws dynamodb wait table-exists --table-name $DYNAMODB_TABLE

# Verify table creation
aws dynamodb describe-table --table-name $DYNAMODB_TABLE
```

## Step 2: Configure Terraform

### 2.1 Clone Repository

```bash
# Clone the repository
git clone https://github.com/koussayx8/devops-platform-infra.git

# Navigate to the project
cd devops-platform-infra
```

### 2.2 Configure Backend

Edit `terraform/backend.tf` with your S3 bucket and DynamoDB table:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-unique-bucket-name"  # Update this
    key            = "devops-platform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

### 2.3 Create terraform.tfvars

```bash
# Copy the example file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit the file
nano terraform/terraform.tfvars
```

**Minimal Configuration for Dev Environment:**

```hcl
# Basic Configuration
aws_region   = "us-east-1"
environment  = "dev"
project_name = "devops-platform"

# Network Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Cost Optimization
enable_nat_gateway = true
single_nat_gateway = true  # Set to false for HA in production

# EKS Configuration
eks_cluster_version     = "1.28"
eks_node_instance_types = ["m7i-flex.large"]
eks_node_capacity_type  = "SPOT"  # Use "ON_DEMAND" for production
eks_node_disk_size      = 20
eks_node_desired_size   = 2
eks_node_max_size       = 4
eks_node_min_size       = 1

# Tags
common_tags = {
  Project    = "devops-platform"
  Owner      = "your-name"
  ManagedBy  = "terraform"
  Repository = "devops-platform-infra"
}
```

### 2.4 Validate Configuration

```bash
cd terraform

# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Expected output:
# Success! The configuration is valid.
```

## Step 3: Deploy Infrastructure

### 3.1 Initialize Terraform

```bash
# Initialize Terraform (downloads providers)
terraform init

# Expected output shows:
# - Initializing backend (S3)
# - Initializing provider plugins (AWS, Kubernetes, Helm)
# - Terraform has been successfully initialized!
```

### 3.2 Review Execution Plan

```bash
# Generate and review the plan
terraform plan -out=tfplan

# This shows:
# - Resources to be created (VPC, EKS, Security Groups, etc.)
# - Estimated changes
# - No destructive changes (first deployment)
```

**Expected Resources (approximately 40-50 resources):**
- VPC and networking (15-20 resources)
- EKS cluster and node group (10-15 resources)
- IAM roles and policies (8-10 resources)
- Security groups (3-5 resources)
- CloudWatch log groups (2-3 resources)

### 3.3 Apply Infrastructure

```bash
# Apply the plan
terraform apply tfplan

# This will:
# 1. Create VPC and subnets (2-3 minutes)
# 2. Create Internet Gateway and NAT Gateway (1-2 minutes)
# 3. Create EKS cluster (10-12 minutes)
# 4. Create node group (3-5 minutes)
# Total time: 15-20 minutes
```

### 3.4 Save Outputs

```bash
# Display all outputs
terraform output

# Save to a file for reference
terraform output -json > terraform-outputs.json

# Get specific outputs
terraform output vpc_id
terraform output eks_cluster_endpoint
terraform output eks_cluster_id
```

**Important Outputs:**
```
eks_cluster_id = "dev-cluster"
eks_cluster_endpoint = "https://xxxxx.eks.us-east-1.amazonaws.com"
vpc_id = "vpc-xxxxx"
```

## Step 4: Configure kubectl

### 4.1 Update kubeconfig

```bash
# Get cluster name from Terraform output
CLUSTER_NAME=$(terraform output -raw eks_cluster_id)
AWS_REGION=$(terraform output -json environment_info | jq -r '.region')

# Update kubeconfig
aws eks update-kubeconfig \
  --region $AWS_REGION \
  --name $CLUSTER_NAME

# Expected output:
# Added new context arn:aws:eks:us-east-1:xxxxx:cluster/dev-cluster to ~/.kube/config
```

### 4.2 Verify Cluster Access

```bash
# Check cluster info
kubectl cluster-info

# Expected output:
# Kubernetes control plane is running at https://xxxxx.eks.us-east-1.amazonaws.com
# CoreDNS is running at https://xxxxx.eks.us-east-1.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# Get nodes
kubectl get nodes

# Expected output:
# NAME                         STATUS   ROLES    AGE   VERSION
# ip-10-0-xx-xx.ec2.internal   Ready    <none>   5m    v1.28.x
# ip-10-0-xx-xx.ec2.internal   Ready    <none>   5m    v1.28.x

# Get all namespaces
kubectl get namespaces

# Check system pods
kubectl get pods -n kube-system
```

## Step 5: Install AWS Load Balancer Controller

The AWS Load Balancer Controller is required for ALB ingress to work.

### 5.1 Create IAM Policy

```bash
# Download IAM policy
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam-policy.json
```

### 5.2 Create IAM Role for Service Account

```bash
# Get cluster name and region
CLUSTER_NAME=$(terraform output -raw eks_cluster_id)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(terraform output -json environment_info | jq -r '.region')

# Create IAM service account
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --region=$AWS_REGION \
  --approve

# If eksctl is not installed, use alternative method (helm with annotations)
```

### 5.3 Install Controller using Helm

```bash
# Add EKS chart repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=$AWS_REGION \
  --set vpcId=$(terraform output -raw vpc_id)

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s \
  deployment/aws-load-balancer-controller -n kube-system
```

### 5.4 Verify Installation

```bash
# Check controller pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify CRDs
kubectl get crd | grep elbv2
```

## Step 6: Deploy ArgoCD

### 6.1 Automated Installation

```bash
# Navigate to scripts directory
cd terraform/scripts

# Make the script executable
chmod +x setup-argocd.sh

# Run the installation script
./setup-argocd.sh

# The script will:
# 1. Check prerequisites
# 2. Install ArgoCD
# 3. Configure ingress
# 4. Setup projects and applications
# 5. Display access information
```

### 6.2 Manual Installation (Alternative)

If the automated script fails, use manual installation:

```bash
# Create namespace
kubectl apply -f ../../argocd/install/namespace.yaml

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.4/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=600s \
  deployment/argocd-server -n argocd

# Apply ingress
kubectl apply -f ../../argocd/install/argocd-ingress.yaml

# Create project and applications
kubectl apply -f ../../argocd/projects/ski-station-project.yaml
kubectl apply -f ../../argocd/applications/monitoring-stack.yaml
kubectl apply -f ../../argocd/applications/ski-station-dev.yaml
```

### 6.3 Get ArgoCD Credentials

```bash
# Get admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo "ArgoCD Admin Password: $ARGOCD_PASSWORD"

# Get ArgoCD URL
ARGOCD_URL=$(kubectl get ingress argocd-server-ingress -n argocd \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "ArgoCD URL: https://$ARGOCD_URL/argocd"
```

### 6.4 Access ArgoCD UI

1. Open browser and navigate to the ArgoCD URL
2. Login with:
   - Username: `admin`
   - Password: (from previous step)
3. You should see the ArgoCD dashboard with your applications

## Step 7: Deploy Applications

### 7.1 Verify ArgoCD Applications

```bash
# List applications
kubectl get applications -n argocd

# Expected output:
# NAME                  SYNC STATUS   HEALTH STATUS
# ski-station-dev       Synced        Healthy
# monitoring-stack      Synced        Healthy

# Get detailed status
kubectl describe application ski-station-dev -n argocd
```

### 7.2 Manual Sync (if needed)

```bash
# Sync ski-station application
kubectl patch application ski-station-dev -n argocd \
  --type merge \
  --patch '{"operation": {"initiatedBy": {"username": "admin"}, "sync": {"revision": "HEAD"}}}'

# Sync monitoring application
kubectl patch application monitoring-stack -n argocd \
  --type merge \
  --patch '{"operation": {"initiatedBy": {"username": "admin"}, "sync": {"revision": "HEAD"}}}'

# Wait for sync to complete
kubectl wait --for=condition=synced --timeout=600s \
  application/ski-station-dev -n argocd
```

### 7.3 Verify Application Pods

```bash
# Check ski-station namespace
kubectl get pods -n ski-station

# Expected pods:
# NAME                                   READY   STATUS    RESTARTS   AGE
# ski-station-api-xxxxxxxxxx-xxxxx       1/1     Running   0          5m
# ski-station-frontend-xxxxxxxxx-xxxxx   1/1     Running   0          5m
# mysql-xxxxxxxxxx-xxxxx                 1/1     Running   0          5m

# Check monitoring namespace
kubectl get pods -n monitoring

# Expected pods:
# NAME                                   READY   STATUS    RESTARTS   AGE
# prometheus-xxxxxxxxxx-xxxxx            1/1     Running   0          5m
# grafana-xxxxxxxxxx-xxxxx               1/1     Running   0          5m
```

## Step 8: Verification

### 8.1 Verify Infrastructure

```bash
# Check all nodes are ready
kubectl get nodes
# All nodes should show STATUS: Ready

# Check all system pods are running
kubectl get pods -A | grep -v Running | grep -v Completed
# Should return empty or only headers

# Check cluster health
kubectl get componentstatuses
```

### 8.2 Verify Applications

```bash
# Check application services
kubectl get svc -n ski-station

# Check application ingress
kubectl get ingress -n ski-station

# Get application URL
APP_URL=$(kubectl get ingress ski-station-ingress -n ski-station \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Application URL: http://$APP_URL"
```

### 8.3 Test Application Endpoints

```bash
# Test frontend (may take a few minutes for ALB to be ready)
curl -I http://$APP_URL/

# Test API health
curl http://$APP_URL/api/actuator/health

# Expected response:
# {"status":"UP"}
```

### 8.4 Verify Monitoring

```bash
# Get Grafana URL
GRAFANA_URL=$(kubectl get ingress grafana-ingress -n monitoring \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Grafana URL: http://$GRAFANA_URL"

# Get Grafana admin password (if configured)
kubectl get secret grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d
```

### 8.5 Check ArgoCD Sync Status

```bash
# Verify all applications are synced and healthy
kubectl get applications -n argocd

# Check sync history
kubectl describe application ski-station-dev -n argocd | grep -A 10 "Sync Result"
```

## Post-Deployment Tasks

### 1. Change Default Passwords

```bash
# Change ArgoCD admin password
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "'$(htpasswd -bnBC 10 "" your-new-password | tr -d ':\n' | sed 's/$2y/$2a/')'",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'

# Change Grafana password (if applicable)
# Access Grafana UI and change from Profile settings
```

### 2. Configure DNS (Optional)

```bash
# Get ALB hostnames
APP_ALB=$(kubectl get ingress ski-station-ingress -n ski-station \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

ARGOCD_ALB=$(kubectl get ingress argocd-server-ingress -n argocd \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

GRAFANA_ALB=$(kubectl get ingress grafana-ingress -n monitoring \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Create CNAME records in your DNS provider:
# app.yourdomain.com     -> $APP_ALB
# argocd.yourdomain.com  -> $ARGOCD_ALB
# grafana.yourdomain.com -> $GRAFANA_ALB
```

### 3. Setup SSL/TLS (Optional)

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer for Let's Encrypt
# Update ingress annotations with TLS configuration
```

### 4. Configure Backups

```bash
# Enable EBS snapshots for persistent volumes
# Configure MySQL backup cron job
# Setup Velero for cluster backups (optional)
```

### 5. Setup Monitoring Alerts

```bash
# Access Grafana
# Configure alert notification channels (Slack, email, etc.)
# Create alert rules for critical metrics
```

### 6. Document Infrastructure

- Save all passwords in secure password manager
- Document custom configurations
- Update team documentation
- Share access credentials with team

## Environment-Specific Configurations

### Development Environment

```hcl
environment            = "dev"
eks_node_capacity_type = "SPOT"
eks_node_min_size      = 1
eks_node_desired_size  = 2
eks_node_max_size      = 3
single_nat_gateway     = true
```

### Staging Environment

```hcl
environment            = "staging"
eks_node_capacity_type = "SPOT"  # or mix of SPOT and ON_DEMAND
eks_node_min_size      = 2
eks_node_desired_size  = 3
eks_node_max_size      = 5
single_nat_gateway     = false  # HA with multiple NAT gateways
```

### Production Environment

```hcl
environment            = "prod"
eks_node_capacity_type = "ON_DEMAND"  # or 70% ON_DEMAND, 30% SPOT
eks_node_min_size      = 3
eks_node_desired_size  = 4
eks_node_max_size      = 10
single_nat_gateway     = false  # HA required
enable_pod_security_policy = true
```

## Troubleshooting

### Issue 1: Terraform Apply Fails

**Symptom:** Terraform apply fails with permission errors

**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify IAM permissions
# Ensure user/role has required permissions

# Re-initialize if needed
terraform init -upgrade
```

### Issue 2: EKS Cluster Not Accessible

**Symptom:** kubectl commands fail with connection errors

**Solution:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name dev-cluster

# Check cluster status in AWS Console
aws eks describe-cluster --name dev-cluster

# Verify security group rules allow your IP
```

### Issue 3: ArgoCD Applications OutOfSync

**Symptom:** Applications show OutOfSync status

**Solution:**
```bash
# Check application details
kubectl describe application ski-station-dev -n argocd

# Force sync
kubectl patch application ski-station-dev -n argocd \
  --type merge \
  --patch '{"operation":{"sync":{"revision":"HEAD"}}}'

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Issue 4: Pods Not Starting

**Symptom:** Pods stuck in Pending or CrashLoopBackOff

**Solution:**
```bash
# Check pod status
kubectl describe pod <pod-name> -n ski-station

# Check logs
kubectl logs <pod-name> -n ski-station

# Check node resources
kubectl top nodes

# Check events
kubectl get events -n ski-station --sort-by='.lastTimestamp'
```

### Issue 5: Ingress Not Working

**Symptom:** Cannot access application via ALB URL

**Solution:**
```bash
# Check ALB controller
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# Check ingress status
kubectl describe ingress ski-station-ingress -n ski-station

# Verify ALB in AWS Console
aws elbv2 describe-load-balancers

# Check target group health
# Wait 3-5 minutes for ALB provisioning
```

## Cleanup

To destroy all infrastructure:

```bash
# Navigate to terraform directory
cd terraform

# Delete Kubernetes resources first
kubectl delete -f ../argocd/applications/
kubectl delete -f ../argocd/projects/
kubectl delete namespace argocd ski-station monitoring

# Destroy infrastructure
terraform destroy

# Confirm destruction
# This will remove all AWS resources

# Optional: Delete S3 bucket and DynamoDB table
aws s3 rb s3://$BUCKET_NAME --force
aws dynamodb delete-table --table-name $DYNAMODB_TABLE
```

## Next Steps

After successful deployment:

1. **[ArgoCD Setup Guide](./argocd-setup.md)**: Learn GitOps workflows
2. **[Architecture Documentation](./architecture.md)**: Understand the infrastructure
3. **[Troubleshooting Guide](./troubleshooting.md)**: Common issues and solutions
4. **Monitor Resources**: Set up CloudWatch alarms
5. **Implement CI/CD**: Integrate with Jenkins or GitHub Actions
6. **Security Hardening**: Implement additional security measures
7. **Performance Tuning**: Optimize resource allocation

---

**Congratulations! 🎉**

Your DevOps Platform Infrastructure is now deployed and ready for use!

**Need Help?**
- Check [Troubleshooting Guide](./troubleshooting.md)
- Review [Architecture Documentation](./architecture.md)
- Open an issue on GitHub

**Document Version:** 1.0  
**Last Updated:** October 2, 2025  
**Author:** Koussay