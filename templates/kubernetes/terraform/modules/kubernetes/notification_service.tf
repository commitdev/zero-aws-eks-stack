locals {
  # Created in terraform/bootstrap/secrets
  notification_service_secret_name = "${var.project}/kubernetes/${var.environment}/notification-service"
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
  version    = "0.1.0"
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

  set {
    name  = "externalSecret.dataFrom[0]"
    value = local.notification_service_secret_name
  }

  set {
    name  = "application.twilioPhoneNumber"
    value = var.notification_service_twilio_phone_number
  }
}
