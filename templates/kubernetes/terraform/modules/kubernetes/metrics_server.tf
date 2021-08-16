locals {
  metrics_server_namespace = "kube-system"
}


resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  # @TODO : The central chart repo was deprecated but as of late 2020 this chart didn't have an official home.
  # Switch away from this bitnami one when possible. https://github.com/kubernetes-sigs/metrics-server/issues/572
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metrics-server"
  version    = "5.9.2"
  namespace  = local.metrics_server_namespace

  set {
    name  = "apiService.create"
    value = true
  }
}
