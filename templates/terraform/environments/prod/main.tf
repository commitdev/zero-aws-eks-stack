terraform {
  required_version = ">= 0.14"
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
  random_seed = "<% index .Params `randomSeed` %>"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id]
}

# remote state of "shared" - contains mostly IAM users that will be shared between environments
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
  random_seed         = local.random_seed

  # ECR configuration
  ecr_repositories = [] # Should be created by the staging environment

  # EKS configuration
  eks_cluster_version = "1.20"
  eks_node_groups = {
    main = {
      instance_types     = ["t3.medium"]
      asg_min_size       = 2
      asg_max_size       = 4
      # Enable use of spot instances instead of on-demand.
      # This can provide significant cost savings and should be stable due to the use of the termination handler, but means that individuial nodes could be restarted at any time. May not be suitable for clusters with long-running workloads
      use_spot_instances = false
      # This is the normal image. Other possibilities are AL2_x86_64_GPU for gpu instances or AL2_ARM_64 for ARM instances
      ami_type           = "AL2_x86_64"
    }
  }

  # Hosting configuration. Each domain will have a bucket created for it, but may have mulitple aliases pointing to the same bucket.
  # Note that because of the way terraform handles lists, new records should be added to the end of the list.
  hosted_domains = [
    {
      domain : local.domain_name,
      aliases : [],
      signed_urls : false,
      trusted_signers : ["self"],
      cors_origins : [],
      hosted_zone : local.domain_name,
    },
    {
      domain : "<% index .Params `productionFrontendSubdomain` %>${local.domain_name}",
      aliases : [],
      signed_urls : false,
      trusted_signers : ["self"],
      cors_origins : [],
      hosted_zone : local.domain_name,
    },
    <% if eq (index .Params `fileUploads`) "yes" %>{
      domain : "files.${local.domain_name}",
      aliases : [],
      signed_urls : true,
      trusted_signers : ["self"],
      cors_origins : ["https://<% index .Params `productionFrontendSubdomain` %>${local.domain_name}"],
      hosted_zone : local.domain_name,
    },<% end %>
  ]

  # DB configuration
  database = "<% index .Params `database` %>"
  db_instance_class = "db.t3.small"
  db_storage_gb = 100

  # Logging configuration
  logging_type = "<% index .Params `loggingType` %>"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_version          = "7.9"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_az_count            = "2"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_instance_type    = "t2.medium.elasticsearch" # The next larger instance type is "m5.large.elasticsearch" - upgrading an existing cluster may require fully recreating though, as m5.large is the first instance size which supports disk encryption
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_instance_count   = "2" # Must be a mulitple of the az count
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_volume_size_in_gb   = "35" # Maximum value is limited by the instance type
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_create_service_role = false # If in the same AWS account, this would have already been created by the staging env
  # See https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/aes-limits.html

  sendgrid_enabled = <%if eq (index .Params `sendgridApiKey`) "" %>false<% else %>true<% end %>
  sendgrid_api_key_secret_name = "${local.project}-sendgrid-<% index .Params `randomSeed` %>"
  sendgrid_zone_name = local.domain_name

  # Cache configuration
  ## you may define "redis" or "memcached" as your cache store. If you define "none", there will be no cache service launched.
  ## Check https://docs.aws.amazon.com/AmazonElastiCache/latest/mem-ug/SelectEngine.html to compare redis or memcached.
  cache_store = "<% index .Params `cacheStore` %>"

<% if ne (index .Params `cacheStore`) "none" %>
  ## See how to define node and instance type: https://docs.aws.amazon.com/AmazonElastiCache/latest/mem-ug/nodes-select-size.html
  cache_cluster_size  = 1
  cache_instance_type = "cache.r6g.large"
<% end %>

  # Roles configuration
  roles = [
    {
      name         = "developer"
      aws_policy   = data.aws_iam_policy_document.developer_access.json
      k8s_policies = local.k8s_developer_access
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
