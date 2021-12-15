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
  project      = "<% .Name %>"
  region       = "<% index .Params `region` %>"
  account_id   = "<% index .Params `accountId` %>"
  domain_name  = "<% index .Params `productionHostRoot` %>"
  environment  = "prod"
  file_uploads = <% if eq (index .Params `fileUploads`) "yes" %>true<% else %>false<% end %>
  random_seed  = "<% index .Params `randomSeed` %>"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id]
}


# Provision kubernetes resources required to run services/applications
module "kubernetes" {
  source = "../../modules/kubernetes"
  environment         = "prod"

  project             = local.project
  region              = local.region
  allowed_account_ids = [local.account_id]
  random_seed         = local.random_seed
  cf_signing_enabled  = local.file_uploads

  # Authenticate with the EKS cluster via the cluster id
  cluster_name = "${local.project}-prod-${local.region}"

  external_dns_zones    = [local.domain_name]
  external_dns_owner_id = "${local.project}-prod-${local.region}"

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
  vpn_server_address = "10.10.99.0/24"
  vpn_client_publickeys = [
    # ["Test User 1", "10.10.99.201/32", "/B3Q/Hlf+ILInjpehTLk9DZGgybdGdbm0SsG87OnWV0="],
    # ["Test User 2", "10.10.99.202/32", "h2jMuaXNIlx7Z0a3owWFjPsAA8B+ZpQH3FbZK393+08="],
  ]

  domain_name = local.domain_name

  <% if eq (index .Params `userAuth`) "yes" %>user_auth = [
    {
      name                          = local.project
      auth_namespace                = "user-auth"
      kratos_secret_name            = local.project
      frontend_service_domain       = "<% index .Params `productionFrontendSubdomain` %>${local.domain_name}"
      backend_service_domain        = "<% index .Params `productionBackendSubdomain` %>${local.domain_name}"
      whitelisted_return_urls       = ["https://<% index .Params `productionFrontendSubdomain` %>${local.domain_name}"]
      jwks_secret_name              = "${local.project}-${local.environment}-oathkeeper-jwks-${local.random_seed}"
      # This domain or address must be verified by the mail provider (Sendgrid, SES, etc.)
      user_auth_mail_from_address   = "noreply@${local.domain_name}"
      cookie_signing_secret_key    = "${local.project}-${local.environment}-${local.random_seed}"
      kratos_values_override = {}
      oathkeeper_values_override  = {}
    }
    ## User auth: Kratos requires database and a secret (as: `user_auth[0].name`)
    ##  example overriding the smtp adress in kratos_values_override, this will merge with the config
    ##  {
    ##    kratos = {
    ##      courier = {
    ##        smtp = {
    ##          from_address = var.user_auth_mail_from_address
    ##        }
    ##      }
    ##    }
    ##  }
    ## Oathkeeper requires a private key (as `user_auth[0].jwks_secret_name`)
    ## per environment one of each (database/database secret/private key) is created in the pre-k8s step
    ## If you need to add another user-auth instance you will have to create another set of these resources
  ]<% end %>
  notification_service_enabled          = <%if eq (index .Params `notificationServiceEnabled`) "yes" %>true<% else %>false<% end %>
  notification_service_highly_available = true
  notification_service_twilio_phone_number = "<% index .Params `notificationServiceTwilioPhoneNumber` %>"

  cache_store =  "<% index .Params `cacheStore` %>"

  # Should not be less than 2 for production. 2 can handle a significant amount of traffic and should give a reasonable amount of redundancy in the case of
  # needing to do deployments of the controller or unexpected termination of a node with a controller pod on it.
  nginx_ingress_replicas = 2

  # The Node Termination Handler should be enabled when using spot instances in your cluster, as it is responsible for gracefully draining a node that is due to be terminated.
  # It can also be used to cleanly handle scheduled maintenance events on On-Demand instances, though it runs as a daemonset, so will run 1 pod on each node in your cluster.
  enable_node_termination_handler = false

  # For ease of use, create an "ExternalName" type service called "database" in the <% .Name %> namespace that points at the app db
  create_database_service = <%if ne (index .Params `database`) "none" %>true<% else %>false<% end %>

  # Roles configuration
  k8s_role_mapping = [
    {
      name         = "developer"
      policies = local.k8s_developer_access
      groups   = ["vpn-users"]
    },
    {
      name         = "operator"
      policies = local.k8s_operator_access
      groups   = ["vpn-users"]
    },
    {
      name         = "deployer"
      policies = local.k8s_deployer_access
      groups   = []
    }
  ]
}
