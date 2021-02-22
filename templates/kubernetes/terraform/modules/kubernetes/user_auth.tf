locals {
  # To prevent coupling to rds engine names
  type_map = {
    "postgres" : "postgres",
    "mysql" : "mysql",
  }
  db_type          = local.type_map[data.aws_db_instance.database.engine]
}

module "user_auth" {
  for_each = { for index, auth_instance in var.user_auth : index => auth_instance }
  source                      = "./user_auth"

  project = each.value.name
  auth_domain                 = each.value.auth_domain
  auth_namespace              = each.value.auth_namespace
  frontend_service_domain     = each.value.frontend_service_domain
  backend_service_domain      = each.value.backend_service_domain
  user_auth_mail_from_address = each.value.user_auth_mail_from_address
  jwks_secret_name            = each.value.jwks_secret_name
  k8s_local_exec_context      = local.k8s_exec_context
}
