# Environment entrypoint

locals {
  kubernetes_cluster_name = "${var.project}-${var.environment}-${var.region}"

  users = [
    for u in var.user_role_mapping : {
      name = u.name
      roles = [
        for r in u.roles :
        r.name if contains(var.roles.*.name, r.name) && contains(r.environments, var.environment)
      ]
    }
  ]

  eks_iam_role_mapping = [
    for m in module.user_access.eks_iam_role_mapping : {
      arn    = m.arn
      name   = m.name
      groups = [ m.name ]
    }
  ]
}

data "aws_iam_user" "ci_user" {
  user_name = var.ci_user_name
}

module "vpc" {
  source  = "commitdev/zero/aws//modules/vpc"
  version = "0.1.11"

  project                 = var.project
  environment             = var.environment
  region                  = var.region
  kubernetes_cluster_name = local.kubernetes_cluster_name
  single_nat_gateway      = var.vpc_use_single_nat_gateway
}

# To get the current account id
data "aws_caller_identity" "current" {}

#
# Provision the EKS cluster
module "eks" {
  source  = "commitdev/zero/aws//modules/eks"
  version = "0.1.2"
  providers = {
    aws = aws.for_eks
  }

  project         = var.project
  environment     = var.environment
  cluster_name    = local.kubernetes_cluster_name
  cluster_version = var.eks_cluster_version

  iam_account_id = data.aws_caller_identity.current.account_id

  private_subnets = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  worker_instance_type = var.eks_worker_instance_type
  worker_asg_min_size  = var.eks_worker_asg_min_size
  worker_asg_max_size  = var.eks_worker_asg_max_size
  worker_ami           = var.eks_worker_ami # EKS-Optimized AMI for your region: https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html

  iam_role_mapping = local.eks_iam_role_mapping
}


module "wildcard_domain" {
  source  = "commitdev/zero/aws//modules/certificate"
  version = "0.1.0"

  zone_name   = var.domain_name
  domain_name = "*.${var.domain_name}"
}

module "assets_domains" {
  source  = "commitdev/zero/aws//modules/certificate"
  version = "0.1.0"
  count   = length(var.hosted_domains)
  providers = {
    aws = aws.for_cloudfront
  }

  zone_name         = var.domain_name
  domain_name       = var.hosted_domains[count.index].domain
  alternative_names = var.hosted_domains[count.index].aliases
}

module "s3_hosting" {
  source  = "commitdev/zero/aws//modules/s3_hosting"
  version = "0.1.9"
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
  version = "0.1.2"

  project                   = var.project
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  password_secret_suffix    = var.random_seed
  allowed_security_group_id = module.eks.worker_security_group_id
  instance_class            = var.db_instance_class
  storage_gb                = var.db_storage_gb
  database_engine           = var.database
}

module "ecr" {
  source  = "commitdev/zero/aws//modules/ecr"
  version = "0.0.1"

  environment      = var.environment
  ecr_repositories = var.ecr_repositories
  ecr_principals   = [data.aws_iam_user.ci_user.arn]
}

module "logging" {
  source  = "commitdev/zero/aws//modules/logging"
  version = "0.1.2"

  count = var.logging_type == "kibana" ? 1 : 0

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  elasticsearch_version = var.logging_es_version
  security_groups       = [module.eks.worker_security_group_id]                              # TODO : Add vpn SG when available
  subnet_ids            = slice(module.vpc.private_subnets.*, 1, (1 + var.logging_az_count)) # We will use 2 subnets
  instance_type         = var.logging_es_instance_type
  instance_count        = var.logging_es_instance_count
  ebs_volume_size_in_gb = var.logging_volume_size_in_gb
  create_service_role   = var.logging_create_service_role
}

module "sendgrid" {
  source  = "commitdev/zero/aws//modules/sendgrid"
  version = "0.0.2"
  count   = var.sendgrid_enabled ? 1 : 0

  zone_name                    = var.domain_name
  sendgrid_api_key_secret_name = var.sendgrid_api_key_secret_name
}

module "user_access" {
  source  = "commitdev/zero/aws//modules/user_access"
  version = "0.1.8"

  project     = var.project
  environment = var.environment

  roles = var.roles
  users = local.users
}


output "s3_hosting" {
  value = [
    for p in module.s3_hosting : {
      cloudfront_distribution_id = p.cloudfront_distribution_id
      bucket_arn                 = p.bucket_arn
      cf_signing_enabled         = p.cf_signing_enabled
    }
  ]
}
