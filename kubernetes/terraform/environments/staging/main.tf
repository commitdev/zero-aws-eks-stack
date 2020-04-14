terraform {
  backend "s3" {
    bucket         = "<% .Name %>-staging-terraform-state"
    key            = "infrastructure/terraform/environments/staging/kubernetes"
    encrypt        = true
    region         = "<% index .Params `region` %>"
    dynamodb_table = "<% .Name %>-staging-terraform-state-locks"
  }
}

provider "aws" {
  region  = "<% index .Params `region` %>"
}

# Provision kubernetes resources required to run services/applications
module "kubernetes" {
  source = "../../modules/kubernetes"

  environment = "staging"
  region      = "<% index .Params `region` %>"

  # Authenticate with the EKS cluster via the cluster id
  cluster_name = "<% .Name %>-staging-<% index .Params `region` %>"

  external_dns_zone = "<% index .Params `stagingHost` %>"
  external_dns_owner_id = "<% GenerateUUID %>" # randomly generated ID
}
