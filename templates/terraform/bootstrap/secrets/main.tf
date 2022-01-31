
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

module "notification_service_secret_prod" {
  count   = <%if eq (index .Params `notificationServiceEnabled`) "yes" %>1<% else %>0<% end %>
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name   = "${local.project}/kubernetes/prod/notification-service"
  type   = "map"
  values = {
    SENDGRID_API_KEY  = var.sendgrid_api_key
    SLACK_API_KEY     = var.slack_api_key
    TWILIO_ACCOUNT_ID = var.twilio_account_id
    TWILIO_AUTH_TOKEN = var.twilio_auth_token
  }
  tags   = { notification_svc : local.project }
}

module "notification_service_secret_stage" {
  count   = <%if eq (index .Params `notificationServiceEnabled`) "yes" %>1<% else %>0<% end %>
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name   = "${local.project}/kubernetes/stage/notification-service"
  type   = "map"
  values = {
    SENDGRID_API_KEY  = var.sendgrid_api_key
    SLACK_API_KEY     = var.slack_api_key
    TWILIO_ACCOUNT_ID = var.twilio_account_id
    TWILIO_AUTH_TOKEN = var.twilio_auth_token
  }
  tags   = { notification_svc : local.project }
}

module "auth0_api_secret_prod" {
  count   = <%if eq (index .Params `backendApplicationHosting`) "serverless" %>1<% else %>0<% end %>
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name   = "${local.project}-prod-auth0-api"
  type   = "map"
  values = {
    AUTH0_DOMAIN        = var.productionAuth0TenantDoamin
    AUTH0_CLIENT_ID     = var.productionAuth0TenantClientId
    AUTH0_CLIENT_SECRET = var.productionAuth0TenantClientSecret
  }
  tags   = {
    auth0_api_key : local.project,
    environment   : "prod"
  }
}

module "auth0_api_secret_stage" {
  count   = <%if eq (index .Params `backendApplicationHosting`) "serverless" %>1<% else %>0<% end %>
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name   = "${local.project}-stage-auth0-api"
  type   = "map"
  values = {
    AUTH0_DOMAIN        = var.stagingAuth0TenantDoamin
    AUTH0_CLIENT_ID     = var.stagingAuth0TenantClientId
    AUTH0_CLIENT_SECRET = var.stagingAuth0TenantClientSecret
  }
  tags   = {
    auth0_api_key : local.project,
    environment   : "stage"
  }
}
