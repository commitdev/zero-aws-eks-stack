terraform {
  required_providers {
    auth0 = {
      source  = "alexkappa/auth0"
      version = "~> 0.21.0"
    }
  }
}

# These are created using scripts/import-auth0-api-keys.sh
data "aws_secretsmanager_secret" "api_keys" {
  name = var.secret_name
}

data "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = data.aws_secretsmanager_secret.api_keys.id
}

locals {
  auth0_api_keys_json = jsondecode(data.aws_secretsmanager_secret_version.api_keys.secret_string)
}

provider "auth0" {
  // Needs the following permission
  // read:client_grants create:client_grants, delete:client_grants, update:client_grants,
  // read:clients, update:clients, delete:clients, create:clients
  domain = local.auth0_api_keys_json["AUTH0_DOMAIN"]
  client_id = local.auth0_api_keys_json["AUTH0_CLIENT_ID"]
  client_secret = local.auth0_api_keys_json["AUTH0_CLIENT_SECRET"]
}

