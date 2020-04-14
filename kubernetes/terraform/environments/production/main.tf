terraform {
  backend "s3" {
    bucket         = "<% .Name %>-production-terraform-state"
    key            = "infrastructure/terraform/environments/production/kubernetes"
    encrypt        = true
    region         = "<% index .Params `region` %>"
    dynamodb_table = "<% .Name %>-production-terraform-state-locks"
  }
}

# Provision kubernetes resources required to run services/applications
module "kubernetes" {
  source = "../../modules/kubernetes"

  environment = "production"
  region      = "<% index .Params `region` %>"

  # Authenticate with the EKS cluster via the cluster id
  cluster_name = "<% .Name %>-production-<% index .Params `region` %>"

  external_dns_zone = "<% index .Params `productionHost` %>"
  external_dns_owner_id = "<% GenerateUUID %>" # randomly generated ID
}
