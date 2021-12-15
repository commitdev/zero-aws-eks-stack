
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
  version = "0.4.2"

  replica_count  = var.nginx_ingress_replicas
  enable_metrics = var.metrics_type == "prometheus"
}

resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.project
  }
}


# Enable prefix delegation - this will enable many more IPs to be allocated per-node.
# See https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
resource "null_resource" "enable_prefix_delegation" {

  # This is a static value so it won't be run multiple times.
  # If these env vars get removed somehow, this value can just be incremented.
  triggers = {
    "version" = "1"
  }

  provisioner "local-exec" {
    command = "kubectl set env daemonset aws-node ${local.k8s_exec_context} -n kube-system ENABLE_PREFIX_DELEGATION=true WARM_PREFIX_TARGET=1"
  }

  depends_on = [
    kubernetes_config_map.aws_auth,
    aws_iam_role.access_assumerole,
    kubernetes_cluster_role_binding.access_role,
    null_resource.cert_manager_http_issuer, # This is to prevent a race condition when trying to use an IAM role that was just created
  ]
}
