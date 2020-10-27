provider "mysql" {
  alias    = "main"
  endpoint = var.db_params.db_endpoint
  username = var.db_params.db_master_user
  password = var.db_params.db_master_password
}

resource "mysql_user" "app_user" {
  provider           = mysql.main
  user               = var.db_params.db_app_user
  host               = "%"
  plaintext_password = var.db_params.db_app_password
}

resource "mysql_grant" "app_user" {
  provider   = mysql.main
  user       = mysql_user.app_user.user
  host       = mysql_user.app_user.host
  database   = var.db_params.db_name
  #privileges = ["SELECT", "UPDATE", "DELETE", "INSERT"]
  privileges = ["ALL"]
}


