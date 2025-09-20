# EKS Module

This module creates an Amazon EKS cluster with managed node groups.

## Features

- EKS cluster with configurable Kubernetes version
- Managed node groups with spot instances for cost optimization
- IAM roles and policies following AWS best practices
- OIDC provider for IAM Roles for Service Accounts (IRSA)
- CloudWatch logging for cluster monitoring
- Security groups with proper access controls

## Usage
```hcl
module "eks" {
  source = "./modules/eks"
  
  cluster_name        = "dev-cluster"
  cluster_version     = "1.28"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  node_group_config = {
    instance_types = ["t3.medium"]
    capacity_type  = "SPOT"
    disk_size      = 20
    ami_type       = "AL2_x86_64"
    desired_size   = 2
    max_size       = 4
    min_size       = 1
  }
  
  tags = {
    Environment = "dev"
    Project     = "devops-platform"
  }
}