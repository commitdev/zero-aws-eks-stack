# Environment entrypoint

locals {
  kubernetes_cluster_name = "${var.project}-${var.environment}-${var.region}"
}

data "aws_iam_user" "ci_user" {
  user_name = "${var.project}-ci-user"  # Should have been created in the bootstrap process
}

module "vpc" {
  source = "../../modules/vpc"

  project                 = var.project
  environment             = var.environment
  region                  = var.region
  kubernetes_cluster_name = local.kubernetes_cluster_name
  single_nat_gateway = var.vpc_use_single_nat_gateway
}

# To get the current account id
data "aws_caller_identity" "current" {}

#
# Provision the EKS cluster
module "eks" {
  source = "../../modules/eks"

  project              = var.project
  environment          = var.environment
  cluster_name         = local.kubernetes_cluster_name
  cluster_version      = var.eks_cluster_version

  iam_account_id       = data.aws_caller_identity.current.account_id

  private_subnets      = module.vpc.private_subnets
  vpc_id               = module.vpc.vpc_id

  worker_instance_type = var.eks_worker_instance_type
  worker_asg_min_size  = var.eks_worker_asg_min_size
  worker_asg_max_size  = var.eks_worker_asg_max_size
  worker_ami           = var.eks_worker_ami # EKS-Optimized AMI for your region: https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html
}


module "wildcard_domain" {
  source = "../../modules/certificate"

  region        = var.region
  zone_name     = var.domain_name
  domain_names  = ["*.${var.domain_name}"]
}

module "assets_domains" {
  source = "../../modules/certificate"

  region        = "us-east-1" # For CF, the cert must be in us-east-1
  zone_name     = var.domain_name
  domain_names  = var.s3_hosting_buckets
}

module "s3_hosting" {
  source = "../../modules/s3_hosting"

  buckets                 = var.s3_hosting_buckets
  project                 = var.project
  environment             = var.environment
  certificate_arns        = module.assets_domains.certificate_arns
  route53_zone_id         = module.assets_domains.route53_zone_id
  certificate_validations = module.assets_domains.certificate_validations
}

module "db" {
  source = "../../modules/database"

  project                   = var.project
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  allowed_security_group_id = module.eks.worker_security_group_id
  instance_class            = var.db_instance_class
  storage_gb                = var.db_storage_gb
}

module "ecr" {
  source = "../../modules/ecr"

  environment       = var.environment
  ecr_repositories  = var.ecr_repositories
  ecr_principals    = [data.aws_iam_user.ci_user.arn]
}
