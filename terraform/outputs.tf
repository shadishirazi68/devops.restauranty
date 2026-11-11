
# VPC ID
output "vpc_id" {
  description = "ID of the Restauranty VPC"
  value       = module.vpc.vpc_id
}

# Public Subnets
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

# Private Subnets
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

# Availability Zones
output "availability_zones" {
  description = "Availability Zones used by the VPC"
  value       = module.vpc.azs
}

# NAT Gateway Public IP
output "nat_public_ips" {
  description = "Public IP addresses of NAT Gateways"
  value       = module.vpc.nat_public_ips
}
