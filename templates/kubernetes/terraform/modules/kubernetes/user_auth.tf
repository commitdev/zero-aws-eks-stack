locals {
  # This secret is created by the /scripts/create-db-user.sh script and contains environment variables that will be pulled into a k8s secret automatically by external-secrets
  secrets_manager_secret_name = "${var.project}/kubernetes/${var.environment}/user-auth"
}


## Get generated JWKS content from secret
data "aws_secretsmanager_secret" "jwks_content" {
  count = length(var.user_auth)
  name  = var.user_auth[count.index].jwks_secret_name
}
data "aws_secretsmanager_secret_version" "jwks_content" {
  count     = length(data.aws_secretsmanager_secret.jwks_content)
  secret_id = data.aws_secretsmanager_secret.jwks_content[count.index].id
}

module "user_auth" {
  count   = length(var.user_auth)
  source  = "commitdev/zero/aws//modules/user_auth"
  version = "0.3.6"

  name                        = var.user_auth[count.index].name
  auth_namespace              = var.user_auth[count.index].auth_namespace
  create_namespace            = false
  kratos_secret_name          = var.user_auth[count.index].kratos_secret_name
  frontend_service_domain     = var.user_auth[count.index].frontend_service_domain
  backend_service_domain      = var.user_auth[count.index].backend_service_domain
  user_auth_mail_from_address = var.user_auth[count.index].user_auth_mail_from_address
  whitelisted_return_urls     = var.user_auth[count.index].whitelisted_return_urls
  jwks_content                = data.aws_secretsmanager_secret_version.jwks_content[count.index].secret_string
  cookie_signing_secret_key   = var.user_auth[count.index].cookie_signing_secret_key
  kubectl_extra_args          = local.k8s_exec_context
  external_secret_name        = local.secrets_manager_secret_name

  depends_on = [helm_release.external_secrets]
}
