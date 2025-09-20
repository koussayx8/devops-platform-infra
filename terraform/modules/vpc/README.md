# VPC Module

This module creates a VPC with public and private subnets across multiple Availability Zones.

## Features

- ✅ VPC with custom CIDR block
- ✅ Public and private subnets across 2 AZs
- ✅ Internet Gateway for public internet access
- ✅ NAT Gateway for private subnet internet access (optional)
- ✅ Proper route tables and associations
- ✅ VPC Flow Logs for monitoring
- ✅ Kubernetes-ready subnet tags
- ✅ Cost optimization with single NAT Gateway option

## Usage
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
  
  availability_zones     = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]
  
  single_nat_gateway = true  # Cost optimization
  
  tags = {
    Project = "devops-platform"
    Owner   = "koussay"
  }
}