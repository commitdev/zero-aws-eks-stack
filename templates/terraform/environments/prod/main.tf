terraform {
  required_version = ">= 0.13"
  backend "s3" {
    bucket         = "<% .Name %>-prod-terraform-state"
    key            = "infrastructure/terraform/environments/prod/main"
    encrypt        = true
    region         = "<% index .Params `region` %>"
    dynamodb_table = "<% .Name %>-prod-terraform-state-locks"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.7"
    }
  }
}

locals {
  project     = "<% .Name %>"
  region      = "<% index .Params `region` %>"
  account_id  = "<% index .Params `accountId` %>"
  domain_name = "<% index .Params `productionHostRoot` %>"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id]
}

# remote state of "shared"
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "${local.project}-shared-terraform-state"
    key    = "infrastructure/terraform/environments/shared/main"
    region = local.region
    encrypt = true
    dynamodb_table = "${local.project}-shared-terraform-state-locks"
  }
}

# Instantiate the production environment
module "prod" {
  source      = "../../modules/environment"
  environment = "prod"

  # Project configuration
  project             = local.project
  region              = local.region
  allowed_account_ids = [local.account_id]
  random_seed         = "<% index .Params `randomSeed` %>"

  # ECR configuration
  ecr_repositories = [] # Should be created by the staging environment

  # EKS configuration
  eks_cluster_version      = "1.17"
  eks_worker_instance_type = "t3.medium"
  eks_worker_asg_min_size  = 2
  eks_worker_asg_max_size  = 4

  # EKS-Optimized AMI for your region: https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html
  # https://<% index .Params `region` %>.console.aws.amazon.com/systems-manager/parameters/%252Faws%252Fservice%252Feks%252Foptimized-ami%252F1.17%252Famazon-linux-2%252Frecommended%252Fimage_id/description?region=${local.region}
  eks_worker_ami = "<% index .Params `eksWorkerAMI` %>"

  # Hosting configuration. Each domain will have a bucket created for it, but may have mulitple aliases pointing to the same bucket.
  hosted_domains = [
    { domain : local.domain_name, aliases : [], signed_urls: false },
    { domain : "<% index .Params `productionFrontendSubdomain` %>${local.domain_name}", aliases : [], signed_urls: false },
    <% if eq (index .Params `fileUploads`) "yes" %>{ domain : "files.${local.domain_name}", aliases : [], signed_urls: true },<% end %>
  ]

  domain_name = local.domain_name

  # DB configuration
  database = "<% index .Params `database` %>"
  db_instance_class = "db.t3.small"
  db_storage_gb = 100

  # Logging configuration
  logging_type = "<% index .Params `loggingType` %>"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_version = "7.7"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_az_count = "2"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_instance_type = "m5.large.elasticsearch"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_instance_count = "2" # Must be a mulitple of the az count
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_volume_size_in_gb = "50" # Maximum value is limited by the instance type
  # See https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/aes-limits.html

  sendgrid_enabled = <%if eq (index .Params `sendgridApiKey`) "" %>false<% else %>true<% end %>
  sendgrid_api_key_secret_name = "${local.project}-sendgrid-<% index .Params `randomSeed` %>"

  # Roles configuration
  roles = [
    {
      name         = "developer"
      aws_policy   = data.aws_iam_policy_document.developer_access.json
      k8s_policies = local.k8s_developer_access
    },
    {
      name         = "operator"
      aws_policy   = data.aws_iam_policy_document.operator_access.json
      k8s_policies = local.k8s_operator_access
    }
  ]

  user_role_mapping = data.terraform_remote_state.shared.outputs.user_role_mapping
}
