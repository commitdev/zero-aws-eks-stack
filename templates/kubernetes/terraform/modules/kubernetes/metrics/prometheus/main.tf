locals {
  grafana_hostname = "grafana.${var.internal_domain}"
}

resource "kubernetes_namespace" "metrics" {
  metadata {
    name = "metrics"
    labels = {
      name = "metrics"
    }
  }
}

# Find the VPC
data "aws_vpc" "vpc" {
  tags = {
    Name : "${var.project}-${var.environment}-vpc"

  }
}

# Find the private subnets
data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    environment : var.environment,
    visibility : "private",
  }
}

# Find the worker security group
data "aws_security_group" "eks_workers" {
  tags = {
    Name : "${var.project}-${var.environment}-${var.region}-eks_worker_sg",
  }
}

# Install the prometheus stack, including prometheus-operator and grafana
resource "helm_release" "prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.metrics.metadata[0].name

  values = [
    file("${path.module}/files/prometheus_operator_helm_config.yml")
  ]

  # Grafana dynamic config
  set {
    name  = "grafana.persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.grafana_nfs_pvc.metadata[0].name
  }

  set {
    name  = "grafana.persistence.size"
    value = kubernetes_persistent_volume_claim.grafana_nfs_pvc.spec[0].resources[0].requests.storage
  }

  set {
    name  = "grafana.persistence.accessModes[0]"
    value = tolist(kubernetes_persistent_volume_claim.grafana_nfs_pvc.spec[0].access_modes)[0]
  }

  set {
    name  = "grafana.adminPassword"
    value = var.project
  }

  set {
    name  = "grafana.env.GF_SERVER_ROOT_URL"
    type = "string"
    value = var.internal_domain == "" ? "https://grafana.metrics.svc.cluster.local/" : "https://${local.grafana_hostname}/"
  }

  set {
    name  = "grafana.env.GF_SERVER_DOMAIN"
    type  = "string"
    value = var.internal_domain == "" ? "grafana.metrics.svc.cluster.local" : local.grafana_hostname
  }


  # Prometheus dynamic config
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "${var.prometheus_retention_days}d"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.volumeName"
    value = kubernetes_persistent_volume.prometheus_nfs_pv.metadata[0].name
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]"
    value = tolist(kubernetes_persistent_volume.prometheus_nfs_pv.spec[0].access_modes)[0]
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = kubernetes_persistent_volume.prometheus_nfs_pv.spec[0].storage_class_name
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = kubernetes_persistent_volume.prometheus_nfs_pv.spec[0].capacity.storage
  }

}

# Grafana ingress
resource "kubernetes_ingress" "grafana_ingress" {
  count = var.internal_domain == "" ? 0 : 1

  metadata {
    name      = "grafana-ingress"
    namespace = kubernetes_namespace.metrics.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "nginx.ingress.kubernetes.io/proxy-body-size"    = "512m"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
    }
  }

  spec {
    rule {
      host = local.grafana_hostname

      http {
        path {
          backend {
            service_name = "kube-prometheus-stack-grafana"
            service_port = 80
          }

          path = "/"
        }
      }
    }
  }
}

# Grafana service with a shorter name for ease of use
resource "kubernetes_service" "grafana" {
  depends_on = [helm_release.prometheus_stack]
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.metrics.metadata[0].name

    labels = {
      app = "grafana"
    }
  }

  spec {
    port {
      name        = "service"
      protocol    = "TCP"
      port        = 80
      target_port = "3000"
    }

    selector = {
      "app.kubernetes.io/instance" = "kube-prometheus-stack"
      "app.kubernetes.io/name" = "grafana"
    }

    type                    = "ClusterIP"
  }
}
