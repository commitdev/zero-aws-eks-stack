locals {
  # user-auth:enabled will allow deployer to manage oathkeeper rules, otherwise concats with []
  auth_enabled = <% if eq (index .Params `userAuth`) "yes" %>true<% else %>false<% end %>
  auth_deploy_rules = local.auth_enabled ? [{
      verbs      = ["get", "create", "delete", "patch", "update"]
      api_groups = ["*"]
      resources  = ["rules"]
    }] : []
}

# define AWS policy documents for developer
data "aws_iam_policy_document" "developer_access" {
  # IAM
  statement {
    effect    = "Allow"
    actions   = ["iam:GetGroup"]
    resources = ["arn:aws:iam::${local.account_id}:group/users/${local.project}-developer-${local.environment}"]
  }
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

  # Application secret management - this role can view and edit application secrets in the staging environment
  statement {
    sid       = "ManageApplicationSecrets"
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:${local.project}/kubernetes/${local.environment}/*"]

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

# define AWS policy documents for operator
data "aws_iam_policy_document" "operator_access" {
  # IAM
  statement {
    effect = "Allow"
    actions = [
      "iam:ListRoles",
      "sts:AssumeRole"
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/${local.project}-kubernetes-operator-${local.environment}"]
  }

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
    resources = ["arn:aws:s3:::${data.terraform_remote_state.shared.outputs.cloudtrail_bucket_id}"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${data.terraform_remote_state.shared.outputs.cloudtrail_bucket_id}/*"]
  }

    # Application secret management - this role can view and edit application secrets in the staging environment
  statement {
    sid       = "ManageApplicationSecrets"
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:${local.account_id}:${local.account_id}:secret:${local.project}/kubernetes/${local.environment}/*"]

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
  non_upload_buckets = [for p in module.stage.s3_hosting : p if ! p.cf_signing_enabled]
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

    resources = module.stage.s3_hosting[*].bucket_arn
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
    resources = formatlist("arn:aws:cloudfront::%s:distribution/%s", local.account_id, module.stage.s3_hosting[*].cloudfront_distribution_id)
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

    actions = [
      "s3:ListBucket",
      "s3:PutObject",
    ]
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
    resources = ["arn:aws:iam::${local.account_id}:role/${local.project}-${local.environment}-invoke-authorizer-role"]

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
    sid     = "R53AndLogs"
    actions = [
      "route53:GetHostedZone",
      "route53:ChangeResourceRecordSets",
      "route53:GetChange",
      "logs:CreateLogDelivery",
    ]

    resources = ["*"]
  }

    statement {
    sid     = "SecretsManager"
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      "arn:aws:secretsmanager:*:*:secret:/${local.project}/sam/${local.environment}/*",
      /// temp for DB
      "arn:aws:secretsmanager:*:*:secret:${local.project}/kubernetes/${local.environment}/*",
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

locals {
  # define Kubernetes policy for developer env deployment
  # TODO: given that in a small team, developers are given almost full permissions on Staging here. In the future, may limit the permissions to sub-namepsace per user.
  k8s_developer_env_access = [
    # to support developer environment
    {
      verbs      = ["create", "exec", "list", "get", "delete", "patch", "update", "watch"]
      api_groups = ["*"]
      resources = ["namespaces", "deployments", "deployments/scale", "configmaps", "pods", "pods/log", "pods/status", "pods/portforward", "pods/exec",
        "jobs", "cronjobs", "daemonsets", "endpoints", "events",
        "replicasets", "horizontalpodautoscalers", "horizontalpodautoscalers/status",
        "ingresses", "services", "serviceaccounts",
        "poddisruptionbudgets",
        "secrets", "externalsecrets"
      ]
    }
  ]

  # define Kubernetes policy for developer
  k8s_developer_access = [
    {
      verbs      = ["exec", "list"]
      api_groups = [""]
      resources  = ["pods", "pods/exec", "pods/portforward"]
      }, {
      verbs      = ["get", "list", "watch"]
      api_groups = ["*"]
      resources = ["deployments", "configmaps", "pods", "pods/log", "pods/status", "nodes", "jobs", "cronjobs", "services", "replicasets",
        "daemonsets", "endpoints", "namespaces", "events", "ingresses", "statefulsets", "horizontalpodautoscalers", "horizontalpodautoscalers/status", "replicationcontrollers"
      ]
    }
  ]

  # define Kubernetes policy for operator
  k8s_operator_access = [
    {
      verbs      = ["exec", "create", "list", "get", "delete", "patch", "update", "watch"]
      api_groups = ["*"]
      resources = ["deployments", "configmaps", "pods", "pods/exec", "pods/log", "pods/status", "pods/portforward",
        "nodes", "jobs", "cronjobs", "statefulsets", "secrets", "externalsecrets", "services", "daemonsets", "endpoints", "namespaces", "events", "ingresses",
        "horizontalpodautoscalers", "horizontalpodautoscalers/status",
        "poddisruptionbudgets", "replicasets", "replicationcontrollers"
      ]
    }
  ]

  # define Kubernetes policy for deployer
  k8s_deployer_access = concat([
    {
      verbs      = ["create", "list", "get", "delete", "patch", "update", "watch"]
      api_groups = ["*"]
      resources = ["deployments", "configmaps", "pods", "pods/log", "pods/status",
        "jobs", "cronjobs", "services", "daemonsets", "endpoints", "namespaces", "events", "ingresses",
        "horizontalpodautoscalers", "horizontalpodautoscalers/status",
        "poddisruptionbudgets", "replicasets", "externalsecrets"
      ]
    },
    {
      verbs      = ["create", "delete", "patch", "update"]
      api_groups = ["*"]
      resources  = ["secrets"]
    }
  ], local.auth_deploy_rules)
}
