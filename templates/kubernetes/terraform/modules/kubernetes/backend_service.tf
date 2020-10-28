# File uploading
module "fileupload" {
  source = "./fileupload"

  count = var.cf_signing_enabled ? 1 : 0

  project = var.project
  namespace = kubernetes_namespace.app_namespace.metadata[0].name
}


# Create a database user for the backend application to use. The user/password will be stored as a kubernetes secret which the application can load at run time.

## collect master user/secret
data "aws_db_instance" "main" {
  db_instance_identifier = "${var.project}-${var.environment}"
}
data "aws_secretsmanager_secret" "rds_master" {
  name = "${var.project}-${var.environment}-rds-${var.random_seed}"
}
data "aws_secretsmanager_secret_version" "rds_master" {
  secret_id = data.aws_secretsmanager_secret.rds_master.id
}

## generate new random app password if username or password version changed
locals {
  db_app_user     = var.project
  db_app_password = random_password.db_app_user.result
}
resource "random_password" "db_app_user" {
  length = 16
  special = true
  override_special = "_%@"

  keepers = {
    user     = local.db_app_user
    password = var.db_app_password_version
  }
}

## create default RDS user for application
module "db_app_user" {
<% if eq (index .Params `database`) "mysql" %>
  source = "./db_user/mysql"
<% end %>
<% if eq (index .Params `database`) "postgres" %>
  source = "./db_user/postgresql"
<% end %>

  namespace          = var.project
  db_endpoint        = data.aws_db_instance.main.endpoint
  db_host            = data.aws_db_instance.main.address
  db_master_user     = data.aws_db_instance.main.master_username
  db_master_password = data.aws_secretsmanager_secret_version.rds_master.secret_string
  db_name            = data.aws_db_instance.main.db_name
  db_app_user        = local.db_app_user
  db_app_password    = local.db_app_password
}

## store user/pass into kubernetes secret for application to load at runtime
resource "kubernetes_secret" "db_app_user" {
  metadata {
    name      = var.project
    namespace = var.project
  }

  data = {
    DATABASE_USERNAME = local.db_app_user
    DATABASE_PASSWORD = local.db_app_password
  }

  type = "Opaque"
}
