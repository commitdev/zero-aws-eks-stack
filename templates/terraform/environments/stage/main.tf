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
  random_seed = "<% index .Params `randomSeed` %>"
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

# rds shared db password for dev envrionment
module "rds_dev_secret" {
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name          = "${local.project}-stage-rds-${local.random_seed}-devenv"
  type          = "random"
  random_length = 32
  tags          = map("rds", "${local.project}-stage-devenv")
}

# Instantiate the staging environment
module "stage" {
  source      = "../../modules/environment"
  environment = "stage"

  # Project configuration
  project             = local.project
  region              = local.region
  allowed_account_ids = [local.account_id]
  random_seed         = local.random_seed

  # ECR configuration
  ecr_repositories = [ local.project ]

  # EKS configuration
  eks_cluster_version      = "1.18"
  eks_worker_instance_type = "t3.medium"
  eks_worker_asg_min_size  = 1
  eks_worker_asg_max_size  = 3

  # EKS-Optimized AMI for your region: https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html
  # https://<% index .Params `region` %>.console.aws.amazon.com/systems-manager/parameters/%252Faws%252Fservice%252Feks%252Foptimized-ami%252F1.18%252Famazon-linux-2%252Frecommended%252Fimage_id/description?region=<% index .Params `region` %>
  eks_worker_ami = "<% index .Params `eksWorkerAMI` %>"

  # Hosting configuration. Each domain will have a bucket created for it, but may have mulitple aliases pointing to the same bucket.
  # Note that because of the way terraform handles lists, new records should be added to the end of the list.
  hosted_domains = [
    {
      domain : local.domain_name,
      aliases : [],
      signed_urls : false,
      trusted_signers : ["self"],
      cors_origins : [],
    },
    {
      domain : "<% index .Params `stagingFrontendSubdomain` %>${local.domain_name}",
      aliases : [],
      signed_urls : false,
      trusted_signers : ["self"],
      cors_origins : [],
    },
    <% if eq (index .Params `fileUploads`) "yes" %>{
      domain : "files.${local.domain_name}",
      aliases : [],
      signed_urls : true,
      trusted_signers : ["self"],
      cors_origins : ["https://<% index .Params `stagingFrontendSubdomain` %>${local.domain_name}"],
    },<% end %>
  ]

  domain_name = local.domain_name

  # NAT configuration - NAT allows traffic from private subnets to access the public internet
  
  ## Instead of using AWS NAT gateway, use a NAT instance which is cheaper by about $30/month, though NAT gateways are more reliable. Only recommended for non-production environments.
  vpc_enable_nat_gateway = false

  ## When using NAT gateway, setting this to true will save some money as there a cost per-gateway of about $35/month. However, if the AZ with the gateway goes down nothing in the private subnets will be able to reach the internet. Not recommended for production. Not used if `vpc_enable_nat_gateway` is `false`.
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

  # Cache configuration
  ## you may define "redis" or "memcached" as your cache store. If you define "none", there will be no cache service launched.
  ## Check https://docs.aws.amazon.com/AmazonElastiCache/latest/mem-ug/SelectEngine.html to compare redis or memcached.
  cache_store         = "memcached"

  # Roles configuration
  roles = [
    {
      name         = "developer"
      aws_policy   = data.aws_iam_policy_document.developer_access.json
      k8s_policies = local.k8s_developer_env_access
      k8s_groups   = ["vpn-users"]
    },
    {
      name         = "operator"
      aws_policy   = data.aws_iam_policy_document.operator_access.json
      k8s_policies = local.k8s_operator_access
      k8s_groups   = ["vpn-users"]
    },
    {
      name         = "deployer"
      aws_policy   = data.aws_iam_policy_document.deployer_access.json
      k8s_policies = local.k8s_deployer_access
      k8s_groups   = []
    }
  ]

  user_role_mapping = data.terraform_remote_state.shared.outputs.user_role_mapping
  ci_user_name      = data.terraform_remote_state.shared.outputs.ci_user_name
}
