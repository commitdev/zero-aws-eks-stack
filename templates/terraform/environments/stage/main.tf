terraform {
  required_version = ">= 0.13"
  backend "s3" {
    bucket         = "<% .Name %>-stage-terraform-state"
    key            = "infrastructure/terraform/environments/stage/main"
    encrypt        = true
    region         = "<% index .Params `region` %>"
    dynamodb_table = "<% .Name %>-stage-terraform-state-locks"
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
  domain_name = "<% index .Params `stagingHostRoot` %>"
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

# Instantiate the staging environment
module "stage" {
  source      = "../../modules/environment"
  environment = "stage"

  # Project configuration
  project             = local.project
  region              = local.region
  allowed_account_ids = [local.account_id]
  random_seed         = "<% index .Params `randomSeed` %>"

  # ECR configuration
  ecr_repositories = [ local.project ]

  # EKS configuration
  eks_cluster_version      = "1.17"
  eks_worker_instance_type = "t3.medium"
  eks_worker_asg_min_size  = 1
  eks_worker_asg_max_size  = 3

  # EKS-Optimized AMI for your region: https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html
  # https://${local.region}.console.aws.amazon.com/systems-manager/parameters/%252Faws%252Fservice%252Feks%252Foptimized-ami%252F1.17%252Famazon-linux-2%252Frecommended%252Fimage_id/description?region=${local.region}
  eks_worker_ami = "<% index .Params `eksWorkerAMI` %>"

  hosted_domains = [
    {
      domain : local.domain_name,
      aliases : [],
      signed_urls: false,
      trusted_signers: ["self"],
      cors_origin: [] },
    {
      domain : "<% index .Params `stagingFrontendSubdomain` %>${local.domain_name}",
      aliases : [],
      signed_urls: false,
      trusted_signers: ["self"],
      cors_origin: [] },
    <% if eq (index .Params `fileUploads`) "yes" %>{
      domain : "files.${local.domain_name}",
      aliases : [],
      signed_urls: true,
      trusted_signers: ["self"],
      cors_origin: ["<% index .Params `stagingFrontendSubdomain` %>${local.domain_name}"],
    },<% end %>
  ]

  domain_name = local.domain_name

  # This will save some money as there a cost associated to each NAT gateway, but if the AZ with the gateway
  # goes down, nothing in the private subnets will be able to reach the internet. Not recommended for production.
  vpc_use_single_nat_gateway = true

  # DB configuration
  database = "<% index .Params `database` %>"
  db_instance_class = "db.t3.small"
  db_storage_gb = 20

  # Logging configuration
  logging_type = "<% index .Params `loggingType` %>"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_version = "7.7"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_create_service_role = true # Set this to false if you need to create more than one ES cluster in an AWS account
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_az_count = "1"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_instance_type = "t2.medium.elasticsearch"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_instance_count = "1" # Must be a mulitple of the az count
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_volume_size_in_gb = "10" # Maximum value is limited by the instance type
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
