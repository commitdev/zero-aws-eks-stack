/* data "aws_iam_user" "ci_user" {
   user_name = "cheung0818-ci-user"
} */




locals {
  /* account_id = data.aws_caller_identity.current.account_id */
}

/* resource "aws_iam_group_membership" "sam_deployers" {
  name = "cheung0818-sam-deployers"

  users = [
    data.aws_iam_user.ci_user.user_name
  ]

  group = aws_iam_group.access_group.name

  depends_on = [data.aws_iam_user.ci_user]
} */

data "aws_route53_zone" "public" {
  name = var.domain_name
}


module "sam_gateway_cert" {
  source  = "commitdev/zero/aws//modules/certificate"
  version = "0.4.0"

  zone_name         = var.domain_name
  domain_name       = "${var.backend_domain_prefix}${var.domain_name}"
}

resource "aws_cloudwatch_log_group" "sam_api_gateway_logs" {

  name = "/aws/sam/${var.project}/${var.environment}"
  tags = {
    Environment = "stage"
    Application = var.project
  }
}





/* resource "aws_iam_group" "access_group" {
  name = "cheung0818-sam-deployer"
  path = "/"
} */



/* resource "aws_s3_bucket_policy" "serverless_artifacts" {
  bucket     = aws_s3_bucket.serverless_artifacts.id
  policy     = data.aws_iam_policy_document.serverless_artifacts.json
}

data "aws_iam_policy_document" "serverless_artifacts" {
  statement {
    actions   = ["s3:*Object"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.serverless_artifacts.id}/*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_user.ci_user.arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.serverless_artifacts.id}"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_user.ci_user.arn]
    }
  }
} */

