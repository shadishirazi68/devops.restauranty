
# Restauranty Amazon EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  # Allow kubectl access from the local Ubuntu VM
  endpoint_public_access  = true
  endpoint_private_access = true

  # Give the Terraform identity cluster-admin access
  enable_cluster_creator_admin_permissions = true

  # Existing Restauranty VPC and private subnets
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Allow internal node-to-node traffic to frontend NGINX
  node_security_group_additional_rules = {
    ingress_self_frontend_http = {
      description = "Allow frontend HTTP between EKS worker nodes"
      type        = "ingress"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      self        = true
    }
  }

  # Kubernetes system add-ons
  addons = {
    coredns = {}

    kube-proxy = {}

    vpc-cni = {
      before_compute = true

      # Enable enforcement of Kubernetes NetworkPolicies
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
      })
    }

    eks-pod-identity-agent = {
      before_compute = true
    }
  }

  # EKS Managed Worker Nodes
  eks_managed_node_groups = {
    restauranty_nodes = {
      name = "restauranty-nodes"

      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.large"]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      desired_size = 2
      max_size     = 3

      tags = {
        Name = "restauranty-worker-node"
      }
    }
  }

  tags = {
    Project     = "Restauranty"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
