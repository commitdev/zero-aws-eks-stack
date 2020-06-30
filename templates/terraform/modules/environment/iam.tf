# @TODO - sort out creating only a single user but multiple roles per env

# Create KubernetesAdmin role for aws-iam-authenticator
resource "aws_iam_role" "kubernetes_admin_role" {
  name               = "${var.project}-kubernetes-admin-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assumerole_root_policy.json
  description        = "Kubernetes administrator role (for AWS EKS auth)"
}

# Trust relationship to limit access to the k8s admin serviceaccount
data "aws_iam_policy_document" "assumerole_root_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Allow the CI user to assume this role
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_user.ci_user.arn]
    }
  }
}

resource "aws_iam_user_policy_attachment" "circleci_ecr_access" {
  user       = data.aws_iam_user.ci_user.user_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}


# Allow the CI user to list and describe clusters
data "aws_iam_policy_document" "eks_list_and_describe" {
  statement {
    actions = [
      "eks:ListUpdates",
      "eks:ListClusters",
      "eks:DescribeUpdate",
      "eks:DescribeCluster",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_list_and_describe_policy" {
  name_prefix   = "eks-list-and-describe"
  description = "Policy to allow listing and describing EKS clusters for ${var.project} ${var.environment}"
  policy = data.aws_iam_policy_document.eks_list_and_describe.json
}

resource "aws_iam_user_policy_attachment" "ci_user_list_and_describe_policy" {
  user       = data.aws_iam_user.ci_user.user_name
  policy_arn = aws_iam_policy.eks_list_and_describe_policy.arn
}

# Allow the CI user read/write access to the frontend assets bucket and CF invalidations
data "aws_iam_policy_document" "deploy_assets_policy" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = formatlist("arn:aws:s3:::%s", var.s3_hosting_buckets)
  }

  statement {
    actions = [
      "s3:*Object",
      "s3:GetBucketLocation",
    ]

    resources = formatlist("arn:aws:s3:::%s/*", var.s3_hosting_buckets)
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
    resources = formatlist("arn:aws:cloudfront::%s:distribution/%s", data.aws_caller_identity.current.account_id, module.s3_hosting.cloudfront_distribution_ids)
  }
}

resource "aws_iam_policy" "deploy_assets_policy" {
  name_prefix   = "ci-deploy-assets"
  description = "Policy to allow a CI user to deploy assets for ${var.project} ${var.environment}"
  policy = data.aws_iam_policy_document.deploy_assets_policy.json
}

resource "aws_iam_user_policy_attachment" "ci_s3_policy" {
  user       = data.aws_iam_user.ci_user.user_name
  policy_arn = aws_iam_policy.deploy_assets_policy.arn
}
