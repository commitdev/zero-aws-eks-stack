terraform {
  backend "s3" {
    bucket         = "<% .Name %>-stage-terraform-state"
    key            = "infrastructure/terraform/environments/stage/kubernetes"
    encrypt        = true
    region         = "<% index .Params `region` %>"
    dynamodb_table = "<% .Name %>-stage-terraform-state-locks"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.7"
    }
  }
}

locals {
  project      = "<% .Name %>"
  region       = "<% index .Params `region` %>"
  account_id   = "<% index .Params `accountId` %>"
  domain_name  = "<% index .Params `stagingHostRoot` %>"
  file_uploads = <% if eq (index .Params `fileUploads`) "yes" %>true<% else %>false<% end %>
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id]
}

# Provision kubernetes resources required to run services/applications
module "kubernetes" {
  source = "../../modules/kubernetes"
  environment         = "stage"

  project             = local.project
  region              = local.region
  allowed_account_ids = [local.account_id]
  random_seed         = "<% index .Params `randomSeed` %>"
  cf_signing_enabled  = local.file_uploads

  # Authenticate with the EKS cluster via the cluster id
  cluster_name = "${local.project}-stage-${local.region}"

  external_dns_zones     = [local.domain_name]
  external_dns_owner_id = "${local.project}-stage-${local.region}"

  # Registration email for LetsEncrypt
  cert_manager_acme_registration_email = "devops@${local.domain_name}"

  # Logging and Metrics configuration
  logging_type = "<% index .Params `loggingType` %>"
  metrics_type = "<% index .Params `metricsType` %>"
  internal_domain = "" # TODO: Add internal domain support

  # Application policy list - This allows applications running in kubernetes to have access to AWS resources.
  # Specify the service account name, the namespace, and the policy that should be applied.
  # This makes use of IRSA: https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/
  application_policy_list = [
    {
      service_account = "backend-service"
      namespace       = local.project
      policy          = data.aws_iam_policy_document.resource_access_backendservice
    },
    # Add additional mappings here
  ]


  # Wireguard configuration
  vpn_server_address = "10.10.199.0/24"
  vpn_client_publickeys = [
    # ["Test User 1", "10.10.199.201/32", "/B3Q/Hlf+ILInjpehTLk9DZGgybdGdbm0SsG87OnWV0="],
    # ["Test User 2", "10.10.199.202/32", "h2jMuaXNIlx7Z0a3owWFjPsAA8B+ZpQH3FbZK393+08="],
  ]

  domain_name                 = local.domain_name
  <% if eq (index .Params `userAuth`) "yes" %>user_auth = [
    {
      name = local.project
      auth_namespace                = "user-auth"
      frontend_service_domain       = "<% index .Params `stagingFrontendSubdomain` %>.${local.domain_name}"
      backend_service_domain        = "<% index .Params `stagingBackendSubdomain` %>.${local.domain_name}"
      whitelisted_return_urls       = ["https://<% index .Params `stagingFrontendSubdomain` %>.${local.domain_name}"]
      jwks_secret_name              = "${local.project}-${local.environment}-oathkeeper-jwks-${local.random_seed}"
      # This domain or address must be verified by the mail provider (Sendgrid, SES, etc.)
      user_auth_mail_from_address   = "noreply@${local.domain_name}"
      cookie_sigining_secret_key    = "${local.project}-${local.environment}-${local.random_seed}"
    }
    ## User auth: Kratos requires database and a secret (as: `user_auth[0].name`)
    ## Oathkeeper requires a private key (as `user_auth[0].jwks_secret_name`)
    ## per environment one of each (database/database secret/private key) is created in the pre-k8s step
    ## If you need to add another user-auth instance you will have to create another set of these resources
  ]<% end %>
  notification_service_enabled          = <%if eq (index .Params `notificationServiceEnabled`) "yes" %>true<% else %>false<% end %>
  notification_service_highly_available = false

  cache_store = "<% index .Params `cacheStore` %>"
}
