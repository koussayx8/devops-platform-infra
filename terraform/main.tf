module "vpc" {
  source = "./modules/vpc"
  
  environment = var.environment
  vpc_cidr    = "10.0.0.0/16"
  
  tags = {
    Project     = "devops-platform"
    Environment = var.environment
    Owner       = "koussay"
  }
}

# Output the VPC details
output "vpc_details" {
  value = {
    vpc_id             = module.vpc.vpc_id
    public_subnet_ids  = module.vpc.public_subnet_ids
    private_subnet_ids = module.vpc.private_subnet_ids
  }
}