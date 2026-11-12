# AWS Infrastructure Screenshot Index

All screenshots below are prepared for `docs/05-terraform-setup.md`. They are named, sequenced, and saved in `docs/screenshots/05-aws-infrastructure/`.

| Figure | File | Evidence |
|---|---|---|
| 47 | terraform-vpc-plan.png | Terraform network plan: 19 to add |
| 48 | terraform-vpc-apply-complete.png | Network apply: 19 added |
| 49 | aws-restauranty-vpc-resource-map.png | AWS VPC topology |
| 50 | terraform-eks-plan.png | EKS plan: 40 to add |
| 51 | aws-eks-cluster-active.png | EKS ACTIVE and VPC association |
| 52 | aws-eks-managed-nodegroup-active.png | Node group ACTIVE |
| 53 | eks-worker-nodes-ready.png | Two worker nodes Ready |
| 54 | aws-ebs-csi-driver-active.png | EBS CSI Driver ACTIVE |
| 55 | terraform-security-group-fix-plan.png | Restricted TCP/80 rule plan |
| 56 | terraform-security-group-fix-outputs.png | Terraform outputs after networking update (not proof of successful apply on its own) |

**Before publishing publicly:** review screenshots for AWS account identifiers, usernames, public IPs, and other identifiers you prefer to conceal. No passwords or Terraform state files are included in this package.
