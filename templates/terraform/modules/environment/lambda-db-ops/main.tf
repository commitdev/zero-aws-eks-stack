# Even though these functions would be the same on stage/prod, but they need to be associated to VPCs
# from the resource level, so they must be created in each env
module "lambda_function_container_image" {
  source = "terraform-aws-modules/lambda/aws"
  version = "2.19.0"

  function_name = "${var.project}-${var.environment}-db-ops"
  description   = "Database operations lambda functions."

  create_package = false

  image_uri    = module.docker_image.image_uri
  package_type = "Image"

  image_config_command = [
    "sh",
    "-c",
    "/bin/bash ./create-user-db.sh"
  ]

  environment_variables = {}

  vpc_subnet_ids = var.subnet_ids

  vpc_security_group_ids = var.security_group_ids

  lambda_role = aws_iam_role.lambda_execution_role.arn
  attach_network_policy = true
  timeout = 5
}

module "docker_image" {
  source = "terraform-aws-modules/lambda/aws//modules/docker-build"
  version = "2.19.0"

  create_ecr_repo = true
  ecr_repo        = "${var.project}-${var.environment}-lambda-db-ops"
  image_tag       = "1.0.0-${substr(sha1(file("${path.module}/context/Dockerfile")), 0, 7)}-${substr(sha1(file("${path.module}/context/create-user-db.sh")), 0, 7)}"
  source_path     = "${path.module}/context"
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.project}-lambda-db-ops-execution-role"
  description        = "Allow lambda to access VPC"
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
