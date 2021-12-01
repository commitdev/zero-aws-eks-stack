// TODO : move to terrform-aws-zero
data "aws_caller_identity" "current" {}

data "aws_route53_zone" "public" {
  name = var.domain_name
}

module "sam_gateway_cert" {
  source  = "commitdev/zero/aws//modules/certificate"
  version = "0.4.0"

  zone_name         = var.domain_name
  domain_name       = var.backend_domain
}

## Bucket used for storing SAM deployment templates and artifacts
resource "aws_s3_bucket" "serverless_artifacts" {
    bucket = "${var.project}-serverless-${lower(var.random_seed)}"  ## would need random-seed in template (s3 names are global)
    acl    = "private" // The contents should be private
    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
      }
    }
}

module "ecr" {
  source  = "commitdev/zero/aws//modules/ecr"
  version = "0.4.0"

  environment      = var.environment
  ecr_repositories = ["${var.project}-serverless"]
  ecr_principals   = [data.aws_caller_identity.current.arn]
}

resource "aws_cloudwatch_log_group" "sam_api_gateway_logs" {
  name = "/aws/sam/${var.project}/${var.environment}"
  tags = {
    Environment = var.environment
    Application = var.project
  }
}

resource "aws_iam_role" "api_gateway_monitoring" {
  name               = "${var.project}-api-gateway-monitoring"
  description        = "Globally allow API gateway to push logs to cloudwatch"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_monitoring.json
}

resource "aws_iam_role_policy_attachment" "api_gateway_monitoring" {
  role       = aws_iam_role.api_gateway_monitoring.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

data "aws_iam_policy_document" "api_gateway_monitoring" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
        "ops.apigateway.amazonaws.com",
        "apigateway.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.project}-lambda-execution-role"
  description        = "Globally allow lambda to use VPC"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_role.json
}

data "aws_iam_policy_document" "lambda_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}
resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
    role       = aws_iam_role.lambda_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
