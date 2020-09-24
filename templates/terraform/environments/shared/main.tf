locals {
  project     = "<% .Name %>"
  region      = "<% index .Params `region` %>"
  account_id  = "<% index .Params `accountId` %>"
}

terraform {
  required_version = ">= 0.13"
  backend "s3" {
    bucket         = "${local.project}-shared-terraform-state"
    key            = "infrastructure/terraform/environments/shared/main"
    encrypt        = true
    region         = "${local.region}"
    dynamodb_table = "${local.project}-shared-terraform-state-locks"
  }
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
#  ]
}

## Create users
resource "aws_iam_user" "access_user" {
  count = length(local.users)
  name  = "${local.project}-${local.users[count.index].name}"

  tags = {
    for r in local.users[count.index].roles : "role:${r.name}" => join("/", r.environments)
  }
}

output "iam_users" {
  value = aws_iam_user.access_user
}

output "user_role_mapping" {
  value = local.users
}
