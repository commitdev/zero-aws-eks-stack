# define AWS policy documents for developer
data "aws_iam_policy_document" "developer_access" {
  # EKS
  statement {
    effect    = "Allow"
    actions   = ["eks:ListClusters"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.project}-prod*"]
  }

  # ECR
  statement {
    effect = "Allow"
    actions = [
      "ecr:DescribeImages",
      "ecr:DescribeRepositories"
    ]
    resources = ["*"]
  }

  # S3
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::*${local.domain_name}"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::*${local.domain_name}/*"]
  }
}

# define AWS policy documents for operator
data "aws_iam_policy_document" "operator_access" {
  # IAM
  statement {
    effect = "Allow"
    actions = [
      "iam:ListRoles",
      "sts:AssumeRole"
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/${local.project}-kubernetes-operator-prod"]
  }

  # EKS
  statement {
    effect    = "Allow"
    actions   = ["eks:*"]
    resources = ["arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.project}-prod*"]
  }

  # ECR
  statement {
    effect    = "Allow"
    actions   = ["ecr:*"]
    resources = ["*"]
  }

  # S3
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::*${local.domain_name}"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::*${local.domain_name}/*"]
  }

  # CloudTrail
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${data.terraform_remote_state.shared.outputs.cloudtrail_bucket_id}"]

  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${data.terraform_remote_state.shared.outputs.cloudtrail_bucket_id}/*"]
  }
}



locals {
  # define Kubernetes policy for developer
  k8s_developer_access = [
    {
      verbs      = ["exec"]
      api_groups = [""]
      resources  = ["pods", "pods/exec", "pods/log", "pods/portforward"]
      }, {
      verbs      = ["get", "list", "watch"]
      api_groups = [""]
      resources  = ["deployments", "configmaps", "pods", "services", "endpoints"]
    }
  ]

  # define Kubernetes policy for operator
  k8s_operator_access = [
    {
      verbs      = ["exec", "create", "list", "get", "delete", "patch", "update"]
      api_groups = [""]
      resources  = ["deployments", "configmaps", "pods", "secrets", "services", "endpoints"]
    }
  ]
}
