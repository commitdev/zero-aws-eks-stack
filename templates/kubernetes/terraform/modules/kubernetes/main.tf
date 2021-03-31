
module "logging_cloudwatch" {
  count        = var.logging_type == "cloudwatch" ? 1 : 0
  source       = "./logging/cloudwatch"
  environment  = var.environment
  region       = var.region
  cluster_name = var.cluster_name
}

module "logging_kibana" {
  count                = var.logging_type == "kibana" ? 1 : 0
  source               = "./logging/kibana"
  environment          = var.environment
  region               = var.region
  elasticsearch_domain = "${var.project}-${var.environment}-logging"
}

module "metrics_prometheus" {
  count                = var.metrics_type == "prometheus" ? 1 : 0
  source               = "./metrics/prometheus"
  project              = var.project
  environment          = var.environment
  region               = var.region
  cluster_name         = var.cluster_name
  internal_domain      = var.internal_domain
  elasticsearch_domain = var.logging_type == "kibana" ? "${var.project}-${var.environment}-logging" : ""
}

module "ingress" {
  source  = "commitdev/zero/aws//modules/kubernetes/ingress_nginx"
  version = "0.2.1"

  replica_count  = var.nginx_ingress_replicas
  enable_metrics = var.metrics_type == "prometheus"
}

resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.project
  }
}
