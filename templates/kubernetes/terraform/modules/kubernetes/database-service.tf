data "aws_db_instance" "database" {
  db_instance_identifier = "${var.project}-${var.environment}"
}

resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.project
  }
}

resource "kubernetes_service" "app_db" {
  ## this should match the deployable backend's name/namespace
  ## it uses this service to connect and create application user
  ## https://github.com/commitdev/zero-deployable-backend/blob/b2cee21982b1e6a0ac9996e2a1bf214e5bf10ab5/db-ops/create-db-user.sh#L6
  metadata {
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    name      = "database"
  }
  spec {
    type          = "ExternalName"
    external_name = data.aws_db_instance.database.address
  }
}
