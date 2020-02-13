provider "aws" {
  region  = "us-west-2"
}

terraform {
  required_version = ">= 0.12"
}

# Create the CI User
resource "aws_iam_user" "ci_user" {
  name = "ci-user"
}

# Create a keypair to be used by CI systems
resource "aws_iam_access_key" "ci_user" {
  user    = aws_iam_user.ci_user.name
}

# Add the keys to AWS secrets manager
module "ci_user_keys" {
  source  = "../../modules/secret"

  name    = "ci-user-aws-keys"
  type    = "map"
  values  = map("access_key_id", aws_iam_access_key.ci_user.id, "secret_key", aws_iam_access_key.ci_user.secret)
}


 # Create db credentials
 # Unfortunately tf doesn't yet allow you to use for_each with calls to modules
 locals {
   project = "<% .Name %>"
 }

module "db_password-staging" {
  source    = "../../modules/secret"

  name      = "${local.project}-staging-rds-master-password"
  type      = "random"
}

module "db_password-production" {
  source        = "../../modules/secret"

  name          = "${local.project}-production-rds-master-password"
  type          = "random"
  random_length = 32
}
