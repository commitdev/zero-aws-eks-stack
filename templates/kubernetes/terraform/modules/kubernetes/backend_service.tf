# File uploading
module "fileupload" {
  source = "./fileupload"

  count = var.cf_signing_enabled ? 1 : 0

  project = var.project
  namespace = kubernetes_namespace.app_namespace.metadata[0].name
}

# Handle default application user
data "aws_db_instance" "main" {
  db_instance_identifier = "${var.project}-${var.environment}"
}
data "aws_secretsmanager_secret" "rds_master" {
  name = "${var.project}-${var.environment}-rds-E4979217"
}
data "aws_secretsmanager_secret_version" "rds_master" {
  secret_id = data.aws_secretsmanager_secret.rds_master.id
}

locals {
  db_params = {
    db_endpoint        = data.aws_db_instance.main.endpoint
    db_host            = data.aws_db_instance.main.address
    db_master_user     = data.aws_db_instance.main.master_username
    db_master_password = data.aws_secretsmanager_secret_version.rds_master.secret_string
    db_name            = data.aws_db_instance.main.db_name

    db_app_user     = data.aws_db_instance.main.db_name
    #db_app_password = var.db_app_password
    db_app_password = "YjN2dW5zWXRSNjVBx"
  }
}

## Create user
<% if eq (index .Params `database`) "mysql" %>{
module "mysql_db" {
  source = "./mysql"

  db_params = local.db_params
}
}<% end %>

<% if eq (index .Params `database`) "postgres" %>{
module "postgresql_db" {
  source = "./postgresql"

  db_params = local.db_params
}
}<% end %>

resource "kubernetes_secret" "db_app_user" {
  metadata {
    name      = var.project
    namespace = var.project
  }

  data = {
    DATABASE_USERNAME = local.db_params.db_app_user
    DATABASE_PASSWORD = local.db_params.db_app_password
  }

  type = "Opaque"
}
