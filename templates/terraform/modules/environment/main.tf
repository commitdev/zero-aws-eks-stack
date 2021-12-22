# Environment entrypoint

locals {
  kubernetes_cluster_name = "${var.project}-${var.environment}-${var.region}"

  user_access_users = [
    for u in var.user_role_mapping : {
      name = u.name
      roles = [
        for r in u.roles :
        r.name if contains(var.roles.*.name, r.name) && contains(r.environments, var.environment)
      ]
    }
  ]

  user_access_roles = [
    for r in var.roles : {
      name         = r.name
      aws_policy   = r.aws_policy
    }
  ]
}


module "vpc" {
  source  = "commitdev/zero/aws//modules/vpc"
  version = "0.4.0"

  project                 = var.project
  environment             = var.environment
  region                  = var.region
  kubernetes_cluster_name = local.kubernetes_cluster_name
  enable_nat_gateway      = var.vpc_enable_nat_gateway
  single_nat_gateway      = var.vpc_use_single_nat_gateway
  nat_instance_types      = var.vpc_nat_instance_types
}

# To get the current account id
data "aws_caller_identity" "current" {}

#
# Provision the EKS cluster
module "eks" {
  count = var.serverless_enabled ? 0 : 1
  source  = "commitdev/zero/aws//modules/eks"
  version = "0.6.0"
  providers = {
    aws = aws.for_eks
  }

  project         = var.project
  environment     = var.environment
  cluster_name    = local.kubernetes_cluster_name
  cluster_version = var.eks_cluster_version

  addon_vpc_cni_version    = var.eks_addon_vpc_cni_version
  addon_kube_proxy_version = var.eks_addon_kube_proxy_version
  addon_coredns_version    = var.eks_addon_coredns_version

  iam_account_id = data.aws_caller_identity.current.account_id

  private_subnets = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  eks_node_groups = var.eks_node_groups
}

module "assets_domains" {
  source  = "commitdev/zero/aws//modules/certificate"
  version = "0.4.0"
  count   = length(var.hosted_domains)
  providers = {
    aws = aws.for_cloudfront
  }

  zone_name         = var.hosted_domains[count.index].hosted_zone
  domain_name       = var.hosted_domains[count.index].domain
  alternative_names = var.hosted_domains[count.index].aliases
}

module "s3_hosting" {
  source  = "commitdev/zero/aws//modules/s3_hosting"
  version = "0.4.0"
  count   = length(var.hosted_domains)

  cf_signed_downloads    = var.hosted_domains[count.index].signed_urls
  cf_trusted_signers     = var.hosted_domains[count.index].trusted_signers
  allowed_cors_origins   = var.hosted_domains[count.index].cors_origins
  domain                 = var.hosted_domains[count.index].domain
  aliases                = var.hosted_domains[count.index].aliases
  project                = var.project
  environment            = var.environment
  certificate_arn        = module.assets_domains[count.index].certificate_arn
  certificate_validation = module.assets_domains[count.index].certificate_validation
  route53_zone_id        = module.assets_domains[count.index].route53_zone_id
}

module "db" {
  source  = "commitdev/zero/aws//modules/database"
  version = "0.4.0"
  count   = (var.database == "none") ? 0 : 1

  project                   = var.project
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  password_secret_suffix    = var.random_seed
  allowed_security_group_id = !var.serverless_enabled ? module.eks[0].worker_security_group_id : module.serverless_security_group[0].this_security_group_id
  instance_class            = var.db_instance_class
  storage_gb                = var.db_storage_gb
  database_engine           = var.database
}

module "logging" {
  source  = "commitdev/zero/aws//modules/logging"
  version = "0.4.0"

  count = var.logging_type == "kibana" ? 1 : 0

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  elasticsearch_version = var.logging_es_version
  security_groups       = !var.serverless_enabled ? [module.eks[0].worker_security_group_id] : [module.serverless_security_group[0].this_security_group_id]
  subnet_ids            = slice(module.vpc.private_subnets, 0, var.logging_az_count)
  instance_type         = var.logging_es_instance_type
  instance_count        = var.logging_es_instance_count
  ebs_volume_size_in_gb = var.logging_volume_size_in_gb
  create_service_role   = var.logging_create_service_role
}

module "sendgrid" {
  source  = "commitdev/zero/aws//modules/sendgrid"
  version = "0.4.0"
  count   = var.sendgrid_enabled ? 1 : 0

  zone_name                    = var.sendgrid_zone_name
  sendgrid_api_key_secret_name = var.sendgrid_api_key_secret_name
  sendgrid_domain_prefix       = var.sendgrid_domain_prefix
}

module "user_access" {
  source  = "commitdev/zero/aws//modules/user_access"
  version = "0.6.0"

  project     = var.project
  environment = var.environment

  roles = local.user_access_roles
  users = local.user_access_users
}

module "cache" {
  count = var.cache_store == "none" ? 0 : 1

  source  = "commitdev/zero/aws//modules/cache"
  version = "0.4.0"

  project     = var.project
  environment = var.environment

  cache_store = var.cache_store

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_size       = var.cache_cluster_size
  instance_type      = var.cache_instance_type
  availability_zones = module.vpc.azs
  security_groups    = !var.serverless_enabled ? [module.eks[0].worker_security_group_id] : [module.serverless_security_group[0].this_security_group_id]

  redis_transit_encryption_enabled = var.cache_redis_transit_encryption_enabled
}

module "serverless_security_group" {
  count = var.serverless_enabled ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.18.0"

  name        = "${var.project}-${var.environment}-serverless-sg"
  description = "Security group for serverless application"
  vpc_id      = module.vpc.vpc_id

  egress_rules = ["all-all"]

  tags = {
    Env = var.environment
  }
}

module "sam" {
  count = var.serverless_enabled ? 1 : 0
  source = "./sam"

  project = var.project
  environment = var.environment
  region = var.region
  random_seed = var.random_seed
  backend_domain = "${var.backend_domain_prefix}${var.hosted_domains[0].hosted_zone}"
  domain_name = var.hosted_domains[0].hosted_zone
  vpc_subnets = module.vpc.private_subnets
  security_group_id = module.serverless_security_group[0].this_security_group_id

  depends_on = [ module.user_access ]
}

<%if eq (index .Params `backendApplicationHosting`) "kubernetes" %>/* <% end %>
# Auth0 has to be enabled via templating due to the provider declared inside
# so it cannot use `count/depends_on/for_each` from terraform
# and even when all the resource counts are 0 it will attempt to use the credentials
module "auth0" {
  source = "./auth0"

  project = var.project
  environment = var.environment
  frontend_domain = "${var.frontend_domain_prefix}${var.hosted_domains[0].hosted_zone}"
  backend_domain = "${var.backend_domain_prefix}${var.hosted_domains[0].hosted_zone}"
  secret_name = "${var.project}-${var.environment}-auth0-api"
}
<%if eq (index .Params `backendApplicationHosting`) "kubernetes" %>*/<% end %>

module "lambda_db_ops" {
  source = "./lambda-db-ops"

  project = var.project
  environment = var.environment
  subnet_ids = module.vpc.private_subnets
  security_group_ids = !var.serverless_enabled ? [module.eks[0].worker_security_group_id] : [module.serverless_security_group[0].this_security_group_id]
}

output "s3_hosting" {
  description = "used by access policy for s3 hosting bucket"
  value = [
    for p in module.s3_hosting : {
      cloudfront_distribution_id = p.cloudfront_distribution_id
      bucket_arn                 = p.bucket_arn
      cf_signing_enabled         = p.cf_signing_enabled
    }
  ]
}
