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

# define AWS policy documents for deployer
locals {
  non_upload_buckets = [for p in module.prod.s3_hosting : p if ! p.cf_signing_enabled]
}

data "aws_iam_policy_document" "deployer_access" {
  # deploy_assets_policy - Allow the deployers read/write access to the frontend assets bucket and CF invalidations
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = module.prod.s3_hosting[*].bucket_arn
  }

  statement {
    actions = [
      "s3:*Object",
      "s3:GetBucketLocation",
    ]

    resources = formatlist("%s/*", local.non_upload_buckets[*].bucket_arn)
  }

  statement {
    actions = [
      "cloudfront:ListDistributions",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "cloudfront:CreateInvalidation",
    ]
    resources = formatlist("arn:aws:cloudfront::%s:distribution/%s", local.account_id, module.prod.s3_hosting[*].cloudfront_distribution_id)
  }

  # EKS - Allow the CI user to list and describe clusters
  statement {
    actions = [
      "eks:ListUpdates",
      "eks:ListClusters",
      "eks:DescribeUpdate",
      "eks:DescribeCluster",
    ]

    resources = ["*"]
  }

  # ECR - Allow the deployers to manage ECR
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = ["*"]
  }
}


locals {
  # define Kubernetes policy for developer
  k8s_developer_access = [
    {
      verbs      = ["exec", "list"]
      api_groups = [""]
      resources  = ["pods", "pods/exec", "pods/portforward"]
      }, {
      verbs      = ["get", "list", "watch"]
      api_groups = ["*"]
      resources = ["deployments", "configmaps", "pods", "pods/log", "pods/status", "jobs", "cronjobs", "services",
        "daemonsets", "endpoints", "namespaces", "events", "ingresses", "horizontalpodautoscalers", "horizontalpodautoscalers/status"
      ]
    }
  ]

  # define Kubernetes policy for operator
  k8s_operator_access = [
    {
      verbs      = ["exec", "create", "list", "get", "delete", "patch", "update", "watch"]
      api_groups = ["*"]
      resources = ["deployments", "configmaps", "pods", "pods/exec", "pods/log", "pods/status", "pods/portforward",
        "jobs", "cronjobs", "secrets", "services", "daemonsets", "endpoints", "namespaces", "events", "ingresses",
        "horizontalpodautoscalers", "horizontalpodautoscalers/status"
      ]
    }
  ]

  # define Kubernetes policy for deployer
  k8s_deployer_access = [
    {
      verbs      = ["create", "list", "get", "delete", "patch", "update", "watch"]
      api_groups = ["*"]
      resources = ["deployments", "configmaps", "pods", "pods/log", "pods/status",
        "jobs", "cronjobs", "services", "daemonsets", "endpoints", "namespaces", "events", "ingresses",
        "horizontalpodautoscalers", "horizontalpodautoscalers/status"
      ]
    },
    {
      verbs      = ["create", "delete", "patch", "update"]
      api_groups = ["*"]
      resources  = ["secrets"]
    }
  ]
}
