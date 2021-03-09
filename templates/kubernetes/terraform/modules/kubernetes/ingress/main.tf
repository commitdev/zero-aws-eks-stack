locals {
  log_format       = <<EOF
{
 "timestamp": "$time_iso8601",
 "remote_addr": "$remote_addr",
 "remote_user": "$remote_user",
 "request": "$request",
 "status": "$status",
 "request_id": "$req_id",
 "bytes_sent": "$bytes_sent",
 "request_method": "$request_method",
 "request_length": "$request_length",
 "request_time": "$request_time",
 "http_referrer": "$http_referer",
 "http_user_agent": "$http_user_agent",
 "host": "$host",
 "request_proto": "$server_protocol",
 "path": "$uri",
 "request_query": "$args",
 "http_x_forwarded_for": "$proxy_add_x_forwarded_for"
}
EOF
  controller_image = "k8s.gcr.io/ingress-nginx/controller"
  controller_tag   = "v0.41.2"
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
    labels = {
      "app.kubernetes.io/name"    = "ingress-nginx",
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
}

resource "kubernetes_config_map" "nginx_configuration" {
  metadata {
    name      = "nginx-configuration"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "ingress-nginx",
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
  data = {
    proxy-real-ip-cidr     = "0.0.0.0/0",
    use-forwarded-headers  = "true",
    use-proxy-protocol     = "false"
    log-format-escape-json = "true"
    log-format-upstream    = replace(local.log_format, "\n", "")
  }
}

resource "kubernetes_config_map" "tcp_services" {
  metadata {
    name      = "tcp-services"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "ingress-nginx",
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
}

resource "kubernetes_config_map" "udp_services" {
  metadata {
    name      = "udp-services"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "ingress-nginx",
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
}

resource "kubernetes_service_account" "nginx_ingress_serviceaccount" {
  metadata {
    name      = "nginx-ingress-serviceaccount"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "ingress-nginx",
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
}

resource "kubernetes_cluster_role" "nginx_ingress_clusterrole" {
  metadata {
    name = "nginx-ingress-clusterrole"
    labels = {
      "app.kubernetes.io/name"    = "ingress-nginx",
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "nodes", "pods", "secrets"]
  }
  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["nodes"]
  }
  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["services"]
  }
  rule {
    verbs      = ["create", "patch"]
    api_groups = [""]
    resources  = ["events"]
  }
  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
  }
  rule {
    verbs      = ["update"]
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses/status"]
  }
}

resource "kubernetes_role" "nginx_ingress_role" {
  metadata {
    name      = "nginx-ingress-role"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "ingress-nginx",
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["configmaps", "pods", "secrets", "namespaces"]
  }
  rule {
    verbs          = ["get", "update"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["ingress-controller-leader-nginx"]
  }
  rule {
    verbs      = ["create"]
    api_groups = [""]
    resources  = ["configmaps"]
  }
  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["endpoints"]
  }
}

resource "kubernetes_role_binding" "nginx_ingress_role_nisa_binding" {
  metadata {
    name      = "nginx-ingress-role-nisa-binding"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "ingress-nginx",
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "nginx-ingress-serviceaccount"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "nginx-ingress-role"
  }
}

resource "kubernetes_cluster_role_binding" "nginx_ingress_clusterrole_nisa_binding" {
  metadata {
    name = "nginx-ingress-clusterrole-nisa-binding"
    labels = {
      "app.kubernetes.io/name"    = "ingress-nginx",
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "nginx-ingress-serviceaccount"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "nginx-ingress-clusterrole"
  }
}

resource "kubernetes_deployment" "nginx_ingress_controller" {
  depends_on = [
    kubernetes_config_map.tcp_services,
    kubernetes_config_map.udp_services,
  ]
  metadata {
    name      = "nginx-ingress-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "ingress-nginx",
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name"    = "ingress-nginx",
        "app.kubernetes.io/part-of" = "ingress-nginx"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"    = "ingress-nginx",
          "app.kubernetes.io/part-of" = "ingress-nginx"
        }
      }
      spec {
        container {
          name  = "nginx-ingress-controller"
          image = "${local.controller_image}:${local.controller_tag}"
          args = [
            "/nginx-ingress-controller",
            "--configmap=$(POD_NAMESPACE)/nginx-configuration",
            "--tcp-services-configmap=$(POD_NAMESPACE)/tcp-services",
            "--udp-services-configmap=$(POD_NAMESPACE)/udp-services",
            "--publish-service=$(POD_NAMESPACE)/ingress-nginx",
            "--annotations-prefix=nginx.ingress.kubernetes.io"
          ]
          port {
            name           = "http"
            container_port = 80
          }
          port {
            name           = "https"
            container_port = 443
          }
          port {
            name           = "metrics"
            container_port = 10254
          }
          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          liveness_probe {
            http_get {
              path   = "/healthz"
              port   = "10254"
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            timeout_seconds       = 10
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          readiness_probe {
            http_get {
              path   = "/healthz"
              port   = "10254"
              scheme = "HTTP"
            }
            timeout_seconds   = 10
            period_seconds    = 10
            success_threshold = 1
            failure_threshold = 3
          }
          lifecycle {
            pre_stop {
              exec {
                command = ["/wait-shutdown"]
              }
            }
          }
          security_context {
            run_as_user                = 101
            allow_privilege_escalation = true
            capabilities {
              add  = ["NET_BIND_SERVICE"]
              drop = ["ALL"]
            }
          }
        }
        termination_grace_period_seconds = 300
        node_selector                    = { "kubernetes.io/os" = "linux" }
        service_account_name             = "nginx-ingress-serviceaccount"
        automount_service_account_token  = true
      }
    }
  }
}

resource "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "ingress-nginx", # Referenced by prometheus servicemonitor if prometheus is used
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
  spec {
    port {
      name        = "http"
      port        = 80
      target_port = "http"
    }
    port {
      name        = "https"
      port        = 443
      target_port = "https"
    }
    port {
      name        = "metrics"
      port        = 10254
      target_port = "metrics"
    }
    selector = {
      "app.kubernetes.io/name"    = "ingress-nginx",
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
    type                    = "LoadBalancer"
    external_traffic_policy = "Local"
  }
}
