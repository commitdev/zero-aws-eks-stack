terraform {
  backend "s3" {
    bucket         = "<% .Name %>-production-terraform-state"
    key            = "infrastructure/terraform/environments/production/kubernetes"
    encrypt        = true
    region         = "us-west-2"
    dynamodb_table = "<% .Name %>-production-terraform-state-locks"
  }
}

# Provision kubernetes resources required to run services/applications
module "kubernetes" {
  source = "../../modules/kubernetes"

  environment = "production"
  region      = "us-west-2"

  # Authenticate with the EKS cluster via the cluster id
  cluster_name = "production"

  # Assume-role policy used by monitoring fluentd daemonset
  assume_role_policy = data.aws_iam_policy_document.assumerole_root_policy.json

  external_dns_zone = "<% .Name %>.com"
  external_dns_owner_id = "ed4ddcb8-a303-4dd2-a5ed-5bc52d94c576"
  external_dns_assume_roles = [ "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/k8s-production-workers" ]
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
