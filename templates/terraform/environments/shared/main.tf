terraform {
  required_version = ">= 0.13"
  backend "s3" {
    bucket         = "<% .Name %>-shared-terraform-state"
    key            = "infrastructure/terraform/environments/shared/main"
    encrypt        = true
    region         = "<% index .Params `region` %>"
    dynamodb_table = "<% .Name %>-shared-terraform-state-locks"
  }
}

locals {
  project                = "<% .Name %>"
  region                 = "<% index .Params `region` %>"
  account_id             = "<% index .Params `accountId` %>"
  random_seed            = "<% index .Params `randomSeed` %>"
  shared_resource_prefix = "<% if ne (index .Params `sharedResourcePrefix`) "none" %><% index .Params `sharedResourcePrefix` %><% end %>"
  enable_cloudtrail       = <%if eq (index .Params `cloudtrailEnable`) "yes" %>1<% else %>0<% end %>
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id]
}

# Instantiate the environment
locals {
  # Users configuration
  ci_user_name = "${local.project}-ci-user"
  users = [
    {
      name = local.ci_user_name
      roles = [
        { name = "deployer", environments = ["stage", "prod"] }
      ]
      global_roles       = []
      create_access_keys = true
    },
    #    {
    #      name  = "dev1"
    #      roles = [
    #        { name = "developer", environments = ["stage", "prod"] }
    #      ]
    #      global_roles       = ["mfa-required", "console-allowed"]
    #      create_access_keys = false
    #    },
    #    {
    #      name  = "devops1"
    #      roles = [
    #        { name = "developer", environments = ["stage", "prod"] },
    #        { name = "operator",  environments = ["stage"] }
    #      ]
    #      global_roles       = ["mfa-required", "console-allowed"]
    #      create_access_keys = false
    #    },
    #    {
    #      name  = "operator1"
    #      roles = [
    #        { name = "operator", environments = ["stage", "prod"] }
    #      ]
    #      global_roles       = ["mfa-required", "console-allowed"]
    #      create_access_keys = false
    #    },
  ]
}

# Create users
resource "aws_iam_user" "access_user" {
  for_each = { for u in local.users : u.name => u.roles }

  name = each.key

  tags = {
    for r in each.value : "role:${r.name}" => join("/", r.environments)
  }
}

## assign users to MFA-Required group
## This is recommended to be enabled, ensuring that all users must use MFA
## https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-cis-controls.html#securityhub-cis-controls-1.2
resource "aws_iam_group_membership" "mfa_required_group" {
  name = "${local.shared_resource_prefix}mfa-required"

  users = [
    for user in local.users : user.name if contains(user.global_roles, "${local.shared_resource_prefix}mfa-required")
  ]

  group = aws_iam_group.mfa_required.name

  depends_on = [aws_iam_user.access_user]
}

resource "aws_iam_group_membership" "console_allowed_group" {
  name = "${local.shared_resource_prefix}console-allowed"

  users = [
    for user in local.users : user.name if contains(user.global_roles, "${local.shared_resource_prefix}console-allowed")
  ]

  group = aws_iam_group.console_allowed.name

  depends_on = [aws_iam_user.access_user]
}

## Create access/secret key pair and save to secret manager
resource "aws_iam_access_key" "access_user" {
  for_each = { for u in local.users : u.name => u.roles if u.create_access_keys }

  user = aws_iam_user.access_user[each.key].name

  depends_on = [aws_iam_user.access_user]
}

data "aws_iam_user" "ci_user" {
  user_name = local.ci_user_name
  depends_on = [aws_iam_user.access_user]
}

module "ecr" {
  source  = "commitdev/zero/aws//modules/ecr"
  version = "0.4.0"

  environment      = "stage"
  ecr_repositories = [local.project]
  ecr_principals   = [data.aws_iam_user.ci_user.arn]
}


module "secret_keys" {
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  for_each = { for u in local.users : u.name => u.roles if u.create_access_keys }

  name = "${each.key}-aws-keys${local.random_seed}"
  type = "map"
  values = {
    access_key_id : aws_iam_access_key.access_user[each.key].id,
    secret_key : aws_iam_access_key.access_user[each.key].secret
  }
  tags = { project : local.project }

  depends_on = [aws_iam_access_key.access_user]
}

# Enable AWS CloudTrail to help you audit governance, compliance, and operational risk of your AWS account, with logs stored in S3 bucket.
module "cloudtrail" {
  count   = local.enable_cloudtrail
  source  = "commitdev/zero/aws//modules/cloudtrail"
  version = "0.1.10"

  project = local.project

  ## To specify whether to publish events from global services such as IAM and non-API events - https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/EventTypes.html. Note: as this may increase your cost, set it off by default.
  include_global_service_events = false
}

# Outputs
output "iam_users" {
  value = aws_iam_user.access_user
}

output "user_role_mapping" {
  value = [
    for u in local.users : {
      name  = u.name
      roles = u.roles
    }
  ]
}

output "ci_user_name" {
  value = local.ci_user_name
}

output "cloudtrail_bucket_id" {
  value = local.enable_cloudtrail == 1 ? module.cloudtrail.cloudtrail_bucket_id : "not-available"
}
