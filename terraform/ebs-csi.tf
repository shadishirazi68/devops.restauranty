
# IAM trust policy for EKS Pod Identity
data "aws_iam_policy_document" "ebs_csi_trust" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

# IAM role for the EBS CSI Driver
resource "aws_iam_role" "ebs_csi" {
  name = "${var.cluster_name}-ebs-csi"

  assume_role_policy = data.aws_iam_policy_document.ebs_csi_trust.json
}

# Allow the driver to manage EBS volumes
resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role = aws_iam_role.ebs_csi.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2"
}

# Install the Amazon EBS CSI Driver add-on
resource "aws_eks_addon" "ebs_csi" {
  cluster_name = module.eks.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  pod_identity_association {
    service_account = "ebs-csi-controller-sa"
    role_arn        = aws_iam_role.ebs_csi.arn
  }

  depends_on = [
    module.eks,
    aws_iam_role_policy_attachment.ebs_csi
  ]
}
