data "aws_db_instance" "database" {
  db_instance_identifier = "<% .Name %>-${var.environment}"
}

resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = "<% .Name %>"
  }
}

resource "kubernetes_service" "app_db" {
  metadata {  
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    name = "<% .Name %>"
  }
  spec {
    type = "ExternalName"
    external_name = data.aws_db_instance.database.address
  }

  depends_on = [kubernetes_namespace.app_namespace]
}
