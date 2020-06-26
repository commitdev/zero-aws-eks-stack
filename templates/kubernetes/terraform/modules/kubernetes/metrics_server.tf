locals {
  metrics_server_namespace = "kube-system"
}


resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "metrics-server"
  namespace  = local.metrics_server_namespace

  set {
    name  = "args"
    value = "{--kubelet-preferred-address-types=InternalIP}"
  }
  set {
    name  = "image.tag"
    value = "v0.3.6"
  }
}

