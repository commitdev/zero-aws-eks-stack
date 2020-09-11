provider "aws" {
  region  = "<% index .Params `region` %>"
  allowed_account_ids = [ "<% index .Params `accountId` %>" ]
}


terraform {
  required_version = ">= 0.13"
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
  source = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"


  name    = "ci-user-aws-keys<% index .Params `randomSeed` %>"
  type    = "map"
  values  = map("access_key_id", aws_iam_access_key.ci_user.id, "secret_key", aws_iam_access_key.ci_user.secret)
  tags = map("project", local.project)
}

module "rds_master_secret_stage" {
  source = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name = "${local.project}-stage-rds-<% index .Params `randomSeed` %>"
  type          = "random"
  random_length = 32
  tags = map("rds", "${local.project}-stage")
}

module "rds_master_secret_prod" {
  source = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name = "${local.project}-prod-rds-<% index .Params `randomSeed` %>"
  type          = "random"
  random_length = 32
  tags = map("rds", "${local.project}-prod")
}

module "sendgrid_api_key" {
  count = <%if eq (index .Params `sendgridApiKey`) "" %>0<% else %>1<% end %>
  source = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name = "${local.project}-sendgrid-<% index .Params `randomSeed` %>"
  type  = "string"
  value = "<% index .Params `sendgridApiKey` %>"
  tags = map("sendgrid", local.project)
}
