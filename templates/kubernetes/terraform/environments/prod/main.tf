terraform {
  backend "s3" {
    bucket         = "<% .Name %>-prod-terraform-state"
    key            = "infrastructure/terraform/environments/prod/kubernetes"
    encrypt        = true
    region         = "<% index .Params `region` %>"
    dynamodb_table = "<% .Name %>-prod-terraform-state-locks"
  }
}

provider "aws" {
  region  = "<% index .Params `region` %>"
}

# Provision kubernetes resources required to run services/applications
module "kubernetes" {
  source = "../../modules/kubernetes"

  project = "<% .Name %>"

  environment = "prod"
  region      = "<% index .Params `region` %>"

  # Authenticate with the EKS cluster via the cluster id
  cluster_name = "<% .Name %>-prod-<% index .Params `region` %>"

  external_dns_zone = "<% index .Params `productionHostRoot` %>"
  external_dns_owner_id = "<% GenerateUUID %>" # randomly generated ID

  # Registration email for LetsEncrypt
  cert_manager_acme_registration_email = "devops@<% index .Params `productionHostRoot` %>"

  # Logging configuration
  logging_type = "<% index .Params `loggingType` %>"

  # Application policy list
  application_policy_list = [
    {
      service_account = "backend-service"
      namespace       = "<% .Name %>"
      policy          = data.aws_iam_policy_document.resource_access_backendservice
    }
    # could be more policies defined here (if have)
  ]
}
