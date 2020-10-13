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
  project    = "<% .Name %>"
  region     = "<% index .Params `region` %>"
  account_id = "<% index .Params `accountId` %>"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id]
}

# Instantiate the environment
locals {
  # Users configuration
  users = [
    #    {
    #      name  = "dev1"
    #      roles = [
    #        { name = "developer", environments = ["stage", "prod"] }
    #      ]
    #    }, {
    #      name  = "devops1"
    #      roles = [
    #        { name = "developer", environments = ["stage", "prod"] },
    #        { name = "operator",  environments = ["stage"] }
    #      ]
    #    }, {
    #      name  = "operator1"
    #      roles = [
    #        { name = "operator", environments = ["stage", "prod"] }
    #      ]
    #    },
  ]
}

## Create users
resource "aws_iam_user" "access_user" {
  for_each = { for u in local.users : u.name => u.roles }

  name = each.key

  tags = {
    for r in each.value : "role:${r.name}" => join("/", r.environments)
  }
}

# This is recommended to be enabled, ensuring that all users must use MFA
# https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-cis-controls.html#securityhub-cis-controls-1.2
resource "aws_iam_group_membership" "mfa_required_group" {
  name = "mfa-required"

  users = [
    for user in aws_iam_user.access_user : user.name
  ]

  group = aws_iam_group.mfa_required.name
}

resource "aws_iam_group_membership" "console_allowed_group" {
  name = "console-allowed"

  users = [
    for user in aws_iam_user.access_user : user.name
  ]

  group = aws_iam_group.console_allowed.name
}

# Enable AWS CloudTrail to help you audit governance, compliance, and operational risk of your AWS account, with logs stored in S3 bucket.
module "cloudtrail" {
  source = "commitdev/zero/aws//modules/cloudtrail"

  project = local.project

  ## To specify whether to publish events from global services such as IAM and non-API events - https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/EventTypes.html. Note: as this may increase your cost, set it off by default.
  include_global_service_events = false
}


# Outputs
output "iam_users" {
  value = aws_iam_user.access_user
}

output "user_role_mapping" {
  value = local.users
}

output "cloudtrail_s3_bucket" {
  value = module.cloudtrail.cloudtrail_bucket_id
}
