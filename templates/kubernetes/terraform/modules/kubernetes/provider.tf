data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = data.aws_eks_cluster.cluster.name
}

provider "kubernetes" {
  ## This is a workaround because aws-eks-cluster-auth will default to us-east-1
  ## leading to an invalid token to access the cluster
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args        = [
      "eks",
      "get-token",
      "--region",
      var.region,
      "--cluster-name",
      var.cluster_name,
      "--role",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-kubernetes-admin-${var.environment}"]
  }
}
