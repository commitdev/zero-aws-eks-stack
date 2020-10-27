provider "postgresql" {
  alias    = "main"
  host     = var.db_params.db_host
  username = var.db_params.db_master_user
  password = var.db_params.db_master_password
}

resource "postgresql_role" "app_user" {
  provider = postgresql.main
  name     = var.db_params.db_app_user
  password = var.db_params.db_app_password
  login    = true
}

resource "postgresql_grant" "app_user" {
  provider    = postgresql.main
  database    = var.db_params.db_name
  role        = postgresql_role.app_user.name
  schema      = "public"
  object_type = "table"
  #privileges = ["SELECT", "UPDATE", "DELETE", "INSERT"]
  privileges  = ["ALL"]
}
