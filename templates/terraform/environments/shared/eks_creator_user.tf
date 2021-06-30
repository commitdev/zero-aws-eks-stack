
#
# EKS Cluster Creator Role
# This has to be created first because it is used by the aws provider in the main terraform, so it can't be created by
# that same terraform due to a chicken-and-egg situation.

# Cluster creator role
resource "aws_iam_role" "eks_cluster_creator" {
  name               = "${local.project}-eks-cluster-creator"
  assume_role_policy = data.aws_iam_policy_document.assumerole_root_only_policy.json
  description        = "EKS cluster creator role"
}

# Trust relationship
data "aws_iam_policy_document" "assumerole_root_only_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [local.account_id]
    }
  }
}

# Attach AWS managed policy for EKS
resource "aws_iam_role_policy_attachment" "eks_cluster_creator_managed" {
  role       = aws_iam_role.eks_cluster_creator.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Attach additional permissions
resource "aws_iam_role_policy" "eks_cluster_creator" {
  name = "manage_eks"
  role = aws_iam_role.eks_cluster_creator.id

  policy = data.aws_iam_policy_document.eks_manage.json
}

# Allow the cluster creator role to create a cluster
data "aws_iam_policy_document" "eks_manage" {
  statement {
    effect = "Allow"
    actions = [
      "eks:*",
      "ec2:*",
      "autoscaling:*",
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:ListOpenIDConnectProviders",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:ListInstanceProfiles",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:ListInstanceProfilesForRole",
      "iam:TagOpenIDConnectProvider",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:PassRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:GetPolicy",
      "iam:DeletePolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:TagPolicy",
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${local.project}-*",
      "arn:aws:iam::${local.account_id}:role/k8s-${local.project}-*",
      "arn:aws:iam::${local.account_id}:policy/${local.project}-*",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:GetRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"

      values = [
        "eks.amazonaws.com",
        "eks-nodegroup.amazonaws.com",
        "eks-fargate.amazonaws.com",
      ]
    }
  }

}
