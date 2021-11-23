data "aws_iam_group" "deployers" {
  group_name = "${var.project}-deployer-${var.environment}"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_iam_policy" "sam_access_policy" {
  name        = "${data.aws_iam_group.deployers.group_name}-serverless"
  description = "Sam Group policy"
  policy      = data.aws_iam_policy_document.sam_access_policies.json
}

resource "aws_iam_group_policy_attachment" "access_group" {
  group      = data.aws_iam_group.deployers.group_name
  policy_arn = aws_iam_policy.sam_access_policy.arn
}

data "aws_iam_policy_document" "sam_access_policies" {
  source_json = data.aws_iam_policy_document.sam_access.json
}

data "aws_iam_policy_document" "sam_access" {
  statement {
    effect = "Allow"
    actions = [
      "cloudformation:*",
    ]
    resources = [
      "arn:aws:cloudformation:${var.region}:${local.account_id}:stack/aws-sam-cli-managed-default/*",
      "arn:aws:cloudformation:${var.region}:${local.account_id}:stack/${var.project}*",
      "arn:aws:cloudformation:${var.region}:aws:transform/Serverless-*"
    ]
  }
  /* statement {
    actions = [
      "s3:*Object",
      "s3:GetBucketLocation",
    ]

    resources = [
      "arn:aws:s3:::aws-sam-cli-managed-default-samclisourcebucket-*"
    ]
  } */

  statement {
    actions = [
      "ecr:CreateRepository",
      "ecr:SetRepositoryPolicy",
      "ecr:PutImage",
    ]

    resources = [
      "arn:aws:ecr:${var.region}:${local.account_id}:repository/*"
    ]
  }

  statement {
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

    resources = [
      "arn:aws:iam::${local.account_id}:role/${var.project}-${var.environment}-invoke-authorizer-role",
      "arn:aws:iam::${local.account_id}:role/${var.project}-*",
    ]
  }
  statement {
    actions = [
      "apigateway:*",
      "route53:GetHostedZone",
      "route53:ChangeResourceRecordSets",
      "route53:GetChange",
      "logs:CreateLogDelivery",
    ]

    resources = [
      "*",

    ]
  }
  statement {
    actions = [
      "lambda:DeleteFunction",
      "lambda:CreateFunction",
      "lambda:GetFunction",
      "lambda:AddPermission",
      "lambda:RemovePermission",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
    ]

    resources = [
      "arn:aws:lambda:${var.region}:${local.account_id}:function:${var.project}-*",

    ]
  }

  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      "arn:aws:secretsmanager:*:*:secret:${var.project}-stage-auth-oidc*",
      "arn:aws:secretsmanager:*:*:secret:${var.project}-stage-*"

    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/${var.project}/sam/stage/*",
    ]
  }


  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      "arn:aws:secretsmanager:*:*:secret:${var.project}-stage-auth-oidc*",
      /// temp
      "arn:aws:secretsmanager:*:*:secret:${var.project}/kubernetes/stage/*",

    ]
  }

  statement {
    actions = [
      "s3:*Object",
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.serverless_artifacts.id}/*"]
  }
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.serverless_artifacts.id}"]
  }
}

resource "aws_s3_bucket" "serverless_artifacts" {
    bucket = "${var.project}-serverless-${lower(var.random_seed)}"  ## would need random-seed in template (s3 names are global)
    acl    = "private" // The contents will be available through cloudfront, they should not be accessible publicly
    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
      }
    }
}
