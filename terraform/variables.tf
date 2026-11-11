
# AWS Region
variable "aws_region" {
  description = "AWS region for Restauranty"
  type        = string
  default     = "us-east-1"
}

# EKS Cluster
variable "cluster_name" {
  description = "Name of the Restauranty EKS cluster"
  type        = string
  default     = "restauranty-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.36"
}

# VPC Network
variable "vpc_cidr" {
  description = "CIDR block for the Restauranty VPC"
  type        = string
  default     = "10.42.0.0/16"
}

# Public Subnets
variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)

  default = [
    "10.42.1.0/24",
    "10.42.2.0/24"
  ]
}

# Private Subnets
variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)

  default = [
    "10.42.11.0/24",
    "10.42.12.0/24"
  ]
}
