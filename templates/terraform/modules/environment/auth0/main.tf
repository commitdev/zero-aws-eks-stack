resource "auth0_client" "oidc" {
  name = "${var.project} - ${var.environment}"
  description = "Test Applications Long Description"
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

 module "auth_oidc_configs" {
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name   = "${var.project}-${var.environment}-auth-oidc"
  type   = "map"
  values = {
    DOMAIN  = local.auth0_api_keys_json["AUTH0_DOMAIN"]
    CLIENT_ID     = auth0_client.oidc.client_id
    CLIENT_SECRET = auth0_client.oidc.client_secret
  }
  tags   = {  auth : var.project, env : var.environment }
}

output "secret_name" {
  description = "Secret containing the OIDC credentials"
  value       = "${var.project}-${var.environment}-auth-oidc"
}
