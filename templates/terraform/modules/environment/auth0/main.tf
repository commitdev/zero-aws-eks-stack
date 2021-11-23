// TODO : move to terrform-aws-zero
resource "auth0_client" "oidc" {
  name = "${var.project} - ${var.environment}"
  description = "${var.project} - ${var.environment} OIDC Authentication API"
  app_type = "regular_web"
  oidc_conformant = true
  is_first_party = true
  grant_types = [
    "authorization_code",
  ]
  allowed_origins = [
    "https://${var.frontend_domain}",
  ]
  callbacks = [
     "https://${var.backend_domain}/callback"
  ]
  allowed_logout_urls = [
    "https://${var.frontend_domain}"
  ]
  jwt_configuration {
    alg = "RS256"
  }
}

resource "random_id" "cookie_signing_secret" {
  keepers = {
    # Generate a new id each time we switch to a new auth0_client_id
    client_id = local.auth0_api_keys_json["AUTH0_DOMAIN"]
  }
  byte_length = 16
}

 module "auth_oidc_configs" {
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name   = "/${var.project}/sam/${var.environment}/auth-oidc"
  type   = "map"
  values = {
    DOMAIN  = local.auth0_api_keys_json["AUTH0_DOMAIN"]
    CLIENT_ID     = auth0_client.oidc.client_id
    CLIENT_SECRET = auth0_client.oidc.client_secret
    COOKIE_SIGNING_SECRET = random_id.cookie_signing_secret.b64_std
  }
  tags   = {  auth : var.project, env : var.environment }
}

output "secret_name" {
  description = "Secret containing the OIDC credentials"
  value       = "/${var.project}/sam/${var.environment}/auth-oidc"
}
