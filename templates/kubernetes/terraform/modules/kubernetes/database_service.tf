data "aws_db_instance" "database" {
  count                  = var.create_database_service ? 1 : 0
  db_instance_identifier = "${var.project}-${var.environment}"
}

resource "kubernetes_service" "app_db" {
  count = var.create_database_service ? 1 : 0
  ## this should match the backend service's name/namespace
  ## it uses this service to connect and create application user
  ## https://github.com/commitdev/zero-backend-go/blob/b2cee21982b1e6a0ac9996e2a1bf214e5bf10ab5/db-ops/create-db-user.sh#L6
  metadata {
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    name      = "database"
  }
  spec {
    type          = "ExternalName"
    external_name = data.aws_db_instance.database[0].address
  }
}
