# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "Public IPs of NAT Gateways"
  value       = module.vpc.nat_gateway_ips
}

# Environment Information
output "environment_info" {
  description = "Environment information"
  value = {
    environment = var.environment
    region      = var.aws_region
    project     = var.project_name
  }
}

# Network Summary
output "network_summary" {
  description = "Network configuration summary"
  value = {
    vpc_cidr             = module.vpc.vpc_cidr_block
    availability_zones   = var.availability_zones
    public_subnets      = length(module.vpc.public_subnet_ids)
    private_subnets     = length(module.vpc.private_subnet_ids)
    nat_gateways        = length(module.vpc.nat_gateway_ids)
  }
}