locals {
  metrics_server_namespace = "kube-system"
}


resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = data.helm_repository.stable.metadata[0].name
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

