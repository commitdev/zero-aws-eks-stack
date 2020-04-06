# Environment entrypoint

locals {
  kubernetes_cluster_name = "${var.project}-${var.environment}-${var.region}"
}

module "vpc" {
  source = "../../modules/vpc"

  project                 = var.project
  environment             = var.environment
  region                  = var.region
  kubernetes_cluster_name = local.kubernetes_cluster_name
}

# Data sources for EKS IAM
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assumerole_root_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

#
# Provision the EKS cluster
module "eks" {
  source = "../../modules/eks"

  project              = var.project
  environment          = var.environment
  cluster_name         = local.kubernetes_cluster_name
  iam_account_id       = data.aws_caller_identity.current.account_id

  assume_role_policy   = data.aws_iam_policy_document.assumerole_root_policy.json
  private_subnets      = module.vpc.private_subnets
  vpc_id               = module.vpc.vpc_id

  worker_instance_type = var.eks_worker_instance_type
  worker_asg_min_size  = var.eks_worker_asg_min_size
  worker_asg_max_size  = var.eks_worker_asg_max_size
  worker_ami           = var.eks_worker_ami # EKS-Optimized AMI for your region: https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html
}

module "kube2iam" {
  source = "../../modules/kube2iam"

  environment              = var.environment
  eks_worker_iam_role_arn  = module.eks.worker_iam_role_arn
  eks_worker_iam_role_name = module.eks.worker_iam_role_name
  iam_account_id           = data.aws_caller_identity.current.account_id
}

data "aws_iam_user" "ci_user" {
  user_name = "ci-user" # Should have been created in the bootstrap process
}

module "domain" {
  source = "../../modules/domain"

  domain_name = var.domain_name
}

module "s3_hosting" {
  source = "../../modules/s3_hosting"

  buckets         = var.s3_hosting_buckets
  certificate_arn = module.domain.certificate_arn
  project         = var.project
  route53_zone_id = module.domain.route53_zone_id
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
