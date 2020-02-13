terraform {
  backend "s3" {
    bucket         = "<% .Name %>-staging-terraform-state"
    key            = "infrastructure/terraform/environments/staging/kubernetes"
    encrypt        = true
    region         = "us-west-2"
    dynamodb_table = "<% .Name %>-staging-terraform-state-locks"
  }
}

provider "aws" {
  region  = "us-west-2"
}

# Provision kubernetes resources required to run services/applications
module "kubernetes" {
  source = "../../modules/kubernetes"

  environment = "staging"
  region      = "us-west-2"

  # Authenticate with the EKS cluster via the cluster id
  cluster_name = "<% .Name %>-staging-us-west-2"

  # Assume-role policy used by monitoring fluentd daemonset
  assume_role_policy = data.aws_iam_policy_document.assumerole_root_policy.json

  external_dns_zone = "<% .Name %>-staging.com"
  external_dns_owner_id = "d02a5d7c-fde4-474d-bf65-ea88094d62d1"
  external_dns_assume_roles = [ "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/k8s-<% .Name %>-staging-us-west-2-workers" ]
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
