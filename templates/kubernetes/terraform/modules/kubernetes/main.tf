
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

module "ingress" {
  source                     = "./ingress"
  environment                = var.environment
  region                     = var.region
  load_balancer_ssl_cert_arn = ""
}

resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.project
  }
}
