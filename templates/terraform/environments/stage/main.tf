terraform {
  required_version = ">= 0.14"
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

# rds shared db password for dev environment
module "rds_dev_secret" {
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name          = "${local.project}-stage-rds-${local.random_seed}-devenv"
  type          = "random"
  random_length = 32
  tags          = { rds: "${local.project}-stage-devenv" }
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
  eks_cluster_version = "1.20"
  # Cluster addons. These often need to be updated when upgrading the cluster version.
  # See: https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html
  eks_addon_vpc_cni_version    = "v1.7.10-eksbuild.1"
  eks_addon_kube_proxy_version = "v1.20.4-eksbuild.2"
  eks_addon_coredns_version    = "v1.8.3-eksbuild.1"

  eks_node_groups = {
    main = {
      instance_types     = ["t3.medium", "t2.medium", "t3.large"]
      asg_min_size       = 1
      asg_max_size       = 3
      # Enable use of spot instances instead of on-demand.
      # This can provide significant cost savings and should be stable due to the use of the termination handler, but means that individuial nodes could be restarted at any time. May not be suitable for clusters with long-running workloads
      use_spot_instances = true
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
      domain : "<% index .Params `stagingFrontendSubdomain` %>${local.domain_name}",
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
      cors_origins : ["https://<% index .Params `stagingFrontendSubdomain` %>${local.domain_name}"],
      hosted_zone : local.domain_name,
    },<% end %>
  ]

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
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_version          = "7.9"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_create_service_role = true # Set this to false if you need to create more than one ES cluster in an AWS account
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_az_count            = "1"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_instance_type    = "t2.medium.elasticsearch"
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_es_instance_count   = "1" # Must be a mulitple of the az count
  <% if ne (index .Params `loggingType`) "kibana" %># <% end %>logging_volume_size_in_gb   = "10" # Maximum value is limited by the instance type
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
  cache_instance_type = "cache.t2.micro"
<% end %>

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
