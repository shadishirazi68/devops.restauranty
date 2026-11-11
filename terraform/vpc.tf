
# Get available Availability Zones
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

# Restauranty AWS Network
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = "restauranty-vpc"
  cidr = var.vpc_cidr

  # Two Availability Zones
  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    2
  )

  # Public Subnets
  public_subnets = var.public_subnets

  # Private Subnets
  private_subnets = var.private_subnets

  # Internet Gateway
  create_igw = true

  # NAT Gateway for private subnets
  enable_nat_gateway = true
  single_nat_gateway = true

  # DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Public IP settings
  map_public_ip_on_launch = true

  # Kubernetes public Load Balancer
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  # Kubernetes internal Load Balancer
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Project     = "Restauranty"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
