terraform {
  backend "s3" {
    bucket         = "<% .Name %>-development-terraform-state"
    key            = "infrastructure/terraform/environments/development/kubernetes"
    encrypt        = true
    region         = "us-west-2"
    dynamodb_table = "<% .Name %>-development-terraform-state-locks"
  }
}

# Provision kubernetes resources required to run services/applications
module "kubernetes" {
  source = "../../modules/kubernetes"

  environment = "development"
  region      = "us-west-2"

  # Authenticate with the EKS cluster via the cluster id
  cluster_name = "staging"

  # Assume-role policy used by monitoring fluentd daemonset
  assume_role_policy = data.aws_iam_policy_document.assumerole_root_policy.json

  external_dns_zone = "<% .Name %>-staging.com"
  external_dns_owner_id = "6eb1a2cb-23b7-40ca-8d96-9ec020fb71af"
  external_dns_assume_roles = [ "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/k8s-staging-workers" ]
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
