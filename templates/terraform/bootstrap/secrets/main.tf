
locals {
  project        = "<% .Name %>"
  aws_account_id = "<% index .Params `accountId` %>"
}

terraform {
  required_version = ">= 0.13"
}

provider "aws" {
  region              = "<% index .Params `region` %>"
  allowed_account_ids = [local.aws_account_id]
}

module "rds_master_secret_stage" {
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name          = "${local.project}-stage-rds-<% index .Params `randomSeed` %>"
  type          = "random"
  random_length = 32
  tags          = { rds: "${local.project}-stage" }
}

module "rds_master_secret_prod" {
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name          = "${local.project}-prod-rds-<% index .Params `randomSeed` %>"
  type          = "random"
  random_length = 32
  tags          = { rds: "${local.project}-prod" }
}

module "sendgrid_api_key" {
  count   = <%if eq (index .Params `sendgridApiKey`) "" %>0<% else %>1<% end %>
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name  = "${local.project}-sendgrid-<% index .Params `randomSeed` %>"
  type  = "string"
  value = var.sendgrid_api_key
  tags  = { sendgrid: local.project }
}

module "slack_api_key" {
  count   = <%if eq (index .Params `notificationServiceSlackApiKey`) "" %>0<% else %>1<% end %>
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name  = "${local.project}-slack-<% index .Params `randomSeed` %>"
  type  = "string"
  value = var.slack_api_key
  tags  = { slack: local.project }
}
