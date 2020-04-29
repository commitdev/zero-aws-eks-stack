provider "aws" {
  region  = "<% index .Params `region` %>"
  allowed_account_ids = [ "<% index .Params `accountId` %>" ]
}


terraform {
  required_version = ">= 0.12"
}

locals {
  project = "<% .Name %>"
}

# Create the CI User
resource "aws_iam_user" "ci_user" {
  name = "${local.project}-ci-user"
}

# Create a keypair to be used by CI systems
resource "aws_iam_access_key" "ci_user" {
  user    = aws_iam_user.ci_user.name
}

# Add the keys to AWS secrets manager
module "ci_user_keys" {
  source  = "../../modules/secret"

  name_prefix    = "ci-user-aws-keys"
  type    = "map"
  values  = map("access_key_id", aws_iam_access_key.ci_user.id, "secret_key", aws_iam_access_key.ci_user.secret)
}
