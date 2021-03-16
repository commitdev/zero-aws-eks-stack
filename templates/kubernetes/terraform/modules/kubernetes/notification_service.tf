locals {
  # Created in terraform/bootstrap/secrets
  sendgrid_api_key_secret_name = "${var.project}-sendgrid-${var.random_seed}"
  slack_api_key_secret_name    = "${var.project}-slack-${var.random_seed}"
}

data "aws_secretsmanager_secret" "sendgrid_api_key" {
  count = var.notification_service_enabled && var.notification_service_sendgrid_enabled ? 1 : 0
  name  = local.sendgrid_api_key_secret_name
}
data "aws_secretsmanager_secret_version" "sendgrid_api_key" {
  count = var.notification_service_enabled && var.notification_service_sendgrid_enabled ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.sendgrid_api_key[0].id
}

data "aws_secretsmanager_secret" "slack_api_key" {
  count = var.notification_service_enabled && var.notification_service_slack_enabled ? 1 : 0
  name  = local.slack_api_key_secret_name
}
data "aws_secretsmanager_secret_version" "slack_api_key" {
  count     = var.notification_service_enabled && var.notification_service_slack_enabled ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.slack_api_key[0].id
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
  version    = "0.0.5"
  namespace  = kubernetes_namespace.notification_service[0].metadata[0].name

  set {
    name  = "application.structuredLogging"
    value = "true"
  }

  # Uncomment to set the image tag of the application to use separately from the chart version
  # set {
  #   name  = "image.tag"
  #   value = "0.0.0"
  # }

  set {
    name  = "autoscaling.enabled"
    value = var.notification_service_highly_available ? "true" : "false" # If false, deployment replicas will be set to 1 and the replica options below will be ignored
  }
  set {
    name  = "autoscaling.minReplicas"
    value = var.notification_service_highly_available ? "2" : "1"
  }
  set {
    name  = "autoscaling.maxReplicas"
    value = var.notification_service_highly_available ? "4" : "2"
  }

  # These will become secrets provided as env vars
  dynamic set_sensitive {
    for_each = var.notification_service_enabled && var.notification_service_sendgrid_enabled ? [data.aws_secretsmanager_secret_version.sendgrid_api_key[0].secret_string] : []
    iterator = sendgrid_api_key
    content {

      name  = "application.sendgridApiKey"
      value = sendgrid_api_key.value
    }
  }

  dynamic set_sensitive {
    for_each = var.notification_service_enabled && var.notification_service_slack_enabled ? [data.aws_secretsmanager_secret_version.slack_api_key[0].secret_string] : []
    iterator = slack_api_key
    content {

      name  = "application.slackApiKey"
      value = slack_api_key.value
    }
  }
}
