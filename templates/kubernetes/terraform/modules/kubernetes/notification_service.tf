locals {
  sendgrid_api_key_secret_name = "${var.project}-sendgrid-${var.random_seed}" # Created in terraform/bootstrap/secrets
}

data "aws_secretsmanager_secret" "sendgrid_api_key" {
  count = var.notification_service_enabled ? 1 : 0
  name  = local.sendgrid_api_key_secret_name
}
data "aws_secretsmanager_secret_version" "sendgrid_api_key" {
  count     = var.notification_service_enabled ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.sendgrid_api_key[0].id
}

resource "kubernetes_namespace" "notification_service" {
  count = var.notification_service_enabled ? 1 : 0
  metadata {
    name = "notification-service"
  }
}

#
resource "helm_release" "notification_service" {
  count      = var.notification_service_enabled ? 1 : 0
  name       = "zero-notification-service"
  repository = "https://commitdev.github.io/zero-notification-service/"
  chart      = "zero-notification-service"
  version    = "0.0.4"
  namespace  = kubernetes_namespace.notification_service[0].metadata[0].name

  set {
    name  = "application.structuredLogging"
    value = "true"
  }

  # This will become a secret provided as an env var
  set_sensitive {
    name  = "application.sendgridApiKey"
    value = data.aws_secretsmanager_secret_version.sendgrid_api_key[0].secret_string
  }
}
