
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
    resources = ["arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.project}-${local.environment}*"]
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

  # EKS
  statement {
    effect    = "Allow"
    actions   = ["eks:*"]
    resources = ["arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.project}-${local.environment}*"]
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
    resources = ["arn:aws:s3:::*-cloudtrail"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::*-cloudtrail/*"]
  }

  # Application secret management - this role can view and edit application secrets in the production environment
  statement {
    sid       = "ManageApplicationSecrets"
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${local.project}/application/${local.environment}/*"]

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:PutSecretValue",
      "secretsmanager:CreateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:UpdateSecret",
    ]
  }
  statement {
    sid       = "ListSecrets"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["secretsmanager:ListSecrets"]
  }
}

# define AWS policy documents for deployer
locals {
  non_upload_buckets = [for p in module.prod.s3_hosting : p if ! p.cf_signing_enabled]
}

# Combine multiple policy documents into one
data "aws_iam_policy_document" "deployer_access" {
  source_policy_documents = [
    data.aws_iam_policy_document.deployer_frontend_assets_access.json,
    data.aws_iam_policy_document.deployer_ecr_access.json,
    data.aws_iam_policy_document.deployer_sam_access.json,
  ]
}

# Allow the deployer to manage frontend assets in S3 / Cloudfront
data "aws_iam_policy_document" "deployer_frontend_assets_access" {
  # deploy_assets_policy - Allow the deployers read/write access to the frontend assets bucket and CF invalidations
  statement {
    actions = ["s3:ListBucket"]

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
}

# Allow the deployer to manage ECR images
data "aws_iam_policy_document" "deployer_ecr_access" {
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
      "ecr:PutImage",
    ]
    resources = ["arn:aws:ecr:*:${local.account_id}:repository/*"]
  }
}

# Allow the deployer to manage resources created with SAM - most of this policy is from AWS SAM docs
data "aws_iam_policy_document" "deployer_sam_access" {
  statement {
    sid       = "CloudFormationTemplate"
    effect    = "Allow"
    resources = ["arn:aws:cloudformation:*:aws:transform/Serverless-*"]
    actions   = ["cloudformation:CreateChangeSet"]
  }

  statement {
    sid       = "CloudFormationStack"
    effect    = "Allow"
    resources = [
      "arn:aws:cloudformation:${local.region}:${local.account_id}:stack/aws-sam-cli-managed-default/*",
      "arn:aws:cloudformation:${local.region}:${local.account_id}:stack/${local.project}*",
    ]

    actions = [
      "cloudformation:CreateChangeSet",
      "cloudformation:CreateStack",
      "cloudformation:DeleteStack",
      "cloudformation:DescribeChangeSet",
      "cloudformation:DescribeStackEvents",
      "cloudformation:DescribeStacks",
      "cloudformation:ExecuteChangeSet",
      "cloudformation:GetTemplateSummary",
      "cloudformation:ListStackResources",
      "cloudformation:UpdateStack",
    ]
  }

  statement {
    sid       = "S3"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${local.project}-serverless-${lower(local.random_seed)}/*"]

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
  }

  statement {
    sid       = "S3List"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${local.project}-serverless-${lower(local.random_seed)}"]

    actions = ["s3:ListBucket","s3:PutObject"]
  }

  statement {
    sid       = "ECRAuthToken"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ecr:GetAuthorizationToken"]
  }

  statement {
    sid       = "ECRRepo"
    effect    = "Allow"
    resources = ["arn:aws:ecr:${local.region}:${local.account_id}:repository/${local.project}-serverless"]
    actions = [
      "ecr:CreateRepository",
      "ecr:SetRepositoryPolicy",
      "ecr:PutImage",
    ]
  }

  statement {
    sid       = "Lambda"
    effect    = "Allow"
    resources = ["arn:aws:lambda:${local.region}:${local.account_id}:function:${local.project}-*"]

    actions = [
      "lambda:AddPermission",
      "lambda:CreateFunction",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:ListTags",
      "lambda:RemovePermission",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "iam:DetachRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DeleteRolePolicy",
    ]
  }

  statement {
    sid       = "IAM"
    effect    = "Allow"
    resources = ["arn:aws:iam::${local.account_id}:role/${local.project}-*"]

    actions = [
      "iam:AttachRolePolicy",
      "iam:DeleteRole",
      "iam:DetachRolePolicy",
      "iam:GetRole",
      "iam:TagRole",
      "iam:CreateRole",
      "iam:DeleteRolePolicy"
    ]
  }

    statement {
    sid       = "IAMManageGatewayInvokeRole"
    effect    = "Allow"
    resources = [
      "arn:aws:iam::${local.account_id}:role/${local.project}-${local.environment}-invoke-authorizer-role",
      "arn:aws:iam::${local.account_id}:role/${local.project}-${local.environment}-ApiGatewayLoggingRole*",
    ]

    actions = [
      "iam:CreateRole",
      "iam:GetRole",
      "iam:DetachRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:DeleteRole",
      "iam:ListUserTags",
      "iam:ListRoleTags",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:TagUser",
      "iam:TagRole",
      "iam:UntagUser",
      "iam:UntagRole",
      "iam:PassRole"
    ]
  }

  statement {
    sid       = "IAMPassRole"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["iam:PassRole"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }

  statement {
    sid       = "APIGateway"
    effect    = "Allow"
    resources = ["arn:aws:apigateway:*::*"]

    actions = [
      "apigateway:DELETE",
      "apigateway:GET",
      "apigateway:PATCH",
      "apigateway:POST",
      "apigateway:PUT",
      "apigateway:TagResource"
    ]
  }

  statement {
    sid     = "R53"
    actions = [
      "route53:GetHostedZone",
      "route53:ChangeResourceRecordSets",
      "route53:GetChange",
    ]

    resources = ["*"]
  }

  statement {
    sid     = "Cloudwatch"
    actions = [
      "logs:CreateLogDelivery",
      "logs:PutResourcePolicy",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:CreateLogGroup",
      "logs:DescribeResourcePolicies",
      "logs:GetLogDelivery",
      "logs:ListLogDeliveries",
    ]

    resources = ["*"]
  }

  statement {
    sid     = "CloudwatchLogGroup"
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]

    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:*"]
  }
  statement {
    sid     = "SecretsManager"
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      "arn:aws:secretsmanager:*:*:secret:${local.project}/sam/${local.environment}/*",
      /// temp for DB
      "arn:aws:secretsmanager:*:*:secret:${local.project}/application/${local.environment}/*",
    ]
  }

  statement {
    sid     = "ParameterStore"
    effect  = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
    ]

    resources = [
      "arn:aws:ssm:${local.region}:${local.account_id}:parameter/${local.project}/sam/${local.environment}/*",
    ]
  }

  statement {
    sid     = "VPCDescribeResources"
    effect  = "Allow"
    actions = [
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DescribeSecurityGroups",
    ]

    resources = ["*"]
  }
}
