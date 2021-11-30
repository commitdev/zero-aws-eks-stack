terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.4"
    }
  }
}

# Created by bootstrap/secrets
data "aws_iam_role" "eks_cluster_creator" {
  name = "${var.project}-eks-cluster-creator"
}

provider "aws" {
  alias  = "for_cloudfront"
  region = "us-east-1"
}

# Used only for EKS creation to tie "cluster creator" to a role instead of the user who runs terraform
# This allows us to rely on credentials pulled from the EKS cluster instead of the user's local kube config
provider "aws" {
  alias = "for_eks"

  region              = var.region
  allowed_account_ids = var.allowed_account_ids

  assume_role {
    role_arn = data.aws_iam_role.eks_cluster_creator.arn
  }
}

data "aws_eks_cluster" "cluster" {
  count = var.serverless_enabled ? 0 : 1
  provider = aws.for_eks
  name     = module.eks[0].cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  count = var.serverless_enabled ? 0 : 1
  provider = aws.for_eks
  name     = module.eks[0].cluster_id
}

provider "kubernetes" {
  host                   = !var.serverless_enabled ? data.aws_eks_cluster.cluster[0].endpoint : ""
  cluster_ca_certificate = !var.serverless_enabled ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority.0.data) : ""
  token                  = !var.serverless_enabled ? data.aws_eks_cluster_auth.cluster[0].token : ""
}