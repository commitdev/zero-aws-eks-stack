// TODO : move to terrform-aws-zero

data "aws_route53_zone" "public" {
  name = var.domain_name
}

module "sam_gateway_cert" {
  source  = "commitdev/zero/aws//modules/certificate"
  version = "0.4.0"

  zone_name         = var.domain_name
  domain_name       = "${var.backend_domain_prefix}${var.domain_name}"
}

## Bucket used for storing SAM deployment templates and artifacts
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

resource "aws_cloudwatch_log_group" "sam_api_gateway_logs" {

  name = "/aws/sam/${var.project}/${var.environment}"
  tags = {
    Environment = "stage"
    Application = var.project
  }
}

module "ecr" {
  source  = "commitdev/zero/aws//modules/ecr"
  version = "0.4.0"

  environment      = var.environment
  ecr_repositories = [var.project]
  ecr_principals   = [data.aws_iam_user.ci_user.arn]
}
