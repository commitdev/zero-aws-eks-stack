locals {
  termination_handler_namespace = "kube-system"
  termination_handler_helm_values = {
    jsonLogging : true
    enablePrometheusServer : (var.metrics_type == "prometheus") ? 1 : 0

    podMonitor : {
      create : (var.metrics_type == "prometheus")
    }
  }
}

resource "helm_release" "node_termination_handler" {
  count      = var.enable_node_termination_handler ? 1 : 0
  name       = "node-termination-handler"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-node-termination-handler"
  version    = "0.15.0"
  namespace  = local.termination_handler_namespace
  values     = [jsonencode(local.termination_handler_helm_values)]
}
