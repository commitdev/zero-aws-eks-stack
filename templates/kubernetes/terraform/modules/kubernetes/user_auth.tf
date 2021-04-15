module "user_auth" {
  count   = length(var.user_auth)
  source  = "commitdev/zero/aws//modules/user_auth"
  version = "0.1.21"

  name                        = var.user_auth[count.index].name
  auth_namespace              = var.user_auth[count.index].auth_namespace
  create_namespace            = false
  kratos_secret_name          = var.user_auth[count.index].kratos_secret_name
  frontend_service_domain     = var.user_auth[count.index].frontend_service_domain
  backend_service_domain      = var.user_auth[count.index].backend_service_domain
  user_auth_mail_from_address = var.user_auth[count.index].user_auth_mail_from_address
  whitelisted_return_urls     = var.user_auth[count.index].whitelisted_return_urls
  jwks_secret_name            = var.user_auth[count.index].jwks_secret_name
  cookie_sigining_secret_key  = var.user_auth[count.index].cookie_sigining_secret_key
  k8s_local_exec_context      = local.k8s_exec_context
}
