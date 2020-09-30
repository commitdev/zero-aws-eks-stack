terraform {
  backend "s3" {
    bucket         = "<% .Name %>-prod-terraform-state"
    key            = "infrastructure/terraform/environments/prod/kubernetes"
    encrypt        = true
    region         = "<% index .Params `region` %>"
    dynamodb_table = "<% .Name %>-prod-terraform-state-locks"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.7"
    }
  }
}

locals {
  project     = "<% .Name %>"
  region      = "<% index .Params `region` %>"
  account_id  = "<% index .Params `accountId` %>"
  domain_name = "<% index .Params `productionHostRoot` %>"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id]
}


# Provision kubernetes resources required to run services/applications
module "kubernetes" {
  source = "../../modules/kubernetes"

  project = "<% .Name %>"

  cf_signing_enabled = <% if eq (index .Params `fileUploads`) "yes" %>true<% else %>false<% end %>

  environment         = "prod"

  project             = local.project
  region              = local.region
  allowed_account_ids = [local.account_id]
  random_seed         = "<% index .Params `randomSeed` %>"

  # Authenticate with the EKS cluster via the cluster id
  cluster_name = "${local.project}-prod-${local.region}"

  external_dns_zone     = local.domain_name
  external_dns_owner_id = "${local.project}-prod-${local.region}"

  # Registration email for LetsEncrypt
  cert_manager_acme_registration_email = "devops@${local.domain_name}"

  # Logging configuration
  logging_type = "<% index .Params `loggingType` %>"

  # Application policy list - This allows applications running in kubernetes to have access to AWS resources.
  # Specify the service account name, the namespace, and the policy that should be applied.
  # This makes use of IRSA: https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/
  application_policy_list = [
    {
      service_account = "backend-service"
      namespace       = local.project
      policy          = data.aws_iam_policy_document.resource_access_backendservice
    }
    # Add additional mappings here
  ]


  # Wireguard configuration
  vpn_server_address = "10.10.99.0/24"
  vpn_client_publickeys = [
    ["Max C", "10.10.99.201/32", "/B3Q/Hlf+ILInjpehTLk9DZGgybdGdbm0SsG87OnWV0="],
    ["Carter L", "10.10.99.202/32", "h2jMuaXNIlx7Z0a3owWFjPsAA8B+ZpQH3FbZK393+08="],
  ]
}
