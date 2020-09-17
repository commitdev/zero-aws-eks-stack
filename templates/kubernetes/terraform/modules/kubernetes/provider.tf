data "aws_caller_identity" "current" {}


# Created by bootstrap/secrets
data "aws_iam_role" "eks_cluster_creator" {
  name = "${var.project}-eks-cluster-creator"
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
  provider = aws.for_eks
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  provider = aws.for_eks
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}
