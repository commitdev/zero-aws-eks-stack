resource "kubernetes_service_account" "kubernetes_dashboard_user" {
  metadata {
    name      = "dashboard-user"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
  }
}

resource "kubernetes_cluster_role_binding" "kubernetes_dashboard_user" {
  metadata {
    name = "dashboard-user"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "dashboard-user"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
}

resource "kubernetes_namespace" "kubernetes_dashboard" {
  metadata {
    name = "kubernetes-dashboard"
  }
}

resource "kubernetes_service_account" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
    labels    = { k8s-app = "kubernetes-dashboard" }
  }
}

resource "kubernetes_service" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
    labels    = { k8s-app = "kubernetes-dashboard" }
  }
  spec {
    port {
      port        = 443
      target_port = "8443"
    }
    selector = { k8s-app = "kubernetes-dashboard" }
  }
}

resource "kubernetes_secret" "kubernetes_dashboard_certs" {
  metadata {
    name      = "kubernetes-dashboard-certs"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
    labels    = { k8s-app = "kubernetes-dashboard" }
  }
  type = "Opaque"
}

resource "kubernetes_secret" "kubernetes_dashboard_csrf" {
  metadata {
    name      = "kubernetes-dashboard-csrf"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
    labels    = { k8s-app = "kubernetes-dashboard" }
  }
  type = "Opaque"
}

resource "kubernetes_secret" "kubernetes_dashboard_key_holder" {
  metadata {
    name      = "kubernetes-dashboard-key-holder"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
  }
  type = "Opaque"
}

resource "kubernetes_config_map" "kubernetes_dashboard_settings" {
  metadata {
    name      = "kubernetes-dashboard-settings"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
    labels    = { k8s-app = "kubernetes-dashboard" }
  }
}

resource "kubernetes_role" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
    labels    = { k8s-app = "kubernetes-dashboard" }
  }
  rule {
    verbs          = ["get", "update", "delete"]
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs", "kubernetes-dashboard-csrf"]
  }
  rule {
    verbs          = ["get", "update"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["kubernetes-dashboard-settings"]
  }
  rule {
    verbs          = ["proxy"]
    api_groups     = [""]
    resources      = ["services"]
    resource_names = ["heapster", "dashboard-metrics-scraper"]
  }
  rule {
    verbs          = ["get"]
    api_groups     = [""]
    resources      = ["services/proxy"]
    resource_names = ["heapster", "http:heapster:", "https:heapster:", "dashboard-metrics-scraper", "http:dashboard-metrics-scraper"]
  }
}

resource "kubernetes_cluster_role" "kubernetes_dashboard" {
  metadata {
    name   = "kubernetes-dashboard"
    labels = { k8s-app = "kubernetes-dashboard" }
  }
  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
  }
}

resource "kubernetes_role_binding" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
    labels    = { k8s-app = "kubernetes-dashboard" }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "kubernetes-dashboard"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "kubernetes-dashboard"
  }
}

resource "kubernetes_cluster_role_binding" "kubernetes_dashboard" {
  metadata {
    name = "kubernetes-dashboard"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "kubernetes-dashboard"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "kubernetes-dashboard"
  }
}

resource "kubernetes_deployment" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
    labels    = { k8s-app = "kubernetes-dashboard" }
  }
  spec {
    replicas = 1
    selector {
      match_labels = { k8s-app = "kubernetes-dashboard" }
    }
    template {
      metadata {
        labels = { k8s-app = "kubernetes-dashboard" }
      }
      spec {
        volume {
          name = "kubernetes-dashboard-certs"
          secret {
            secret_name = "kubernetes-dashboard-certs"
          }
        }
        volume {
          name = "tmp-volume"
          empty_dir {}
        }
        container {
          name  = "kubernetes-dashboard"
          image = "kubernetesui/dashboard:v2.0.0-rc7"
          args  = ["--auto-generate-certificates", "--namespace=kubernetes-dashboard"]
          port {
            container_port = 8443
            protocol       = "TCP"
          }
          volume_mount {
            name       = "kubernetes-dashboard-certs"
            mount_path = "/certs"
          }
          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
          }
          liveness_probe {
            http_get {
              path   = "/"
              port   = "8443"
              scheme = "HTTPS"
            }
            initial_delay_seconds = 30
            timeout_seconds       = 30
          }
          image_pull_policy = "IfNotPresent"
          security_context {
            run_as_user               = 1001
            run_as_group              = 2001
            read_only_root_filesystem = true
          }
        }
        node_selector                   = { "beta.kubernetes.io/os" = "linux" }
        service_account_name            = "kubernetes-dashboard"
        automount_service_account_token = true
        toleration {
          key    = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
      }
    }
    revision_history_limit = 10
  }
}

resource "kubernetes_service" "dashboard_metrics_scraper" {
  metadata {
    name      = "dashboard-metrics-scraper"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
    labels    = { k8s-app = "dashboard-metrics-scraper" }
  }
  spec {
    port {
      port        = 8000
      target_port = "8000"
    }
    selector = { k8s-app = "dashboard-metrics-scraper" }
  }
}

resource "kubernetes_deployment" "dashboard_metrics_scraper" {
  metadata {
    name      = "dashboard-metrics-scraper"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
    labels    = { k8s-app = "dashboard-metrics-scraper" }
  }
  spec {
    replicas = 1
    selector {
      match_labels = { k8s-app = "dashboard-metrics-scraper" }
    }
    template {
      metadata {
        labels      = { k8s-app = "dashboard-metrics-scraper" }
        annotations = { "seccomp.security.alpha.kubernetes.io/pod" = "runtime/default" }
      }
      spec {
        volume {
          name = "tmp-volume"
          empty_dir {}
        }
        container {
          name  = "dashboard-metrics-scraper"
          image = "kubernetesui/metrics-scraper:v1.0.4"
          port {
            container_port = 8000
            protocol       = "TCP"
          }
          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
          }
          liveness_probe {
            http_get {
              path   = "/"
              port   = "8000"
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            timeout_seconds       = 30
          }
          security_context {
            run_as_user               = 1001
            run_as_group              = 2001
            read_only_root_filesystem = true
          }
        }
        node_selector                   = { "beta.kubernetes.io/os" = "linux" }
        service_account_name            = "kubernetes-dashboard"
        automount_service_account_token = true
        toleration {
          key    = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
      }
    }
    revision_history_limit = 10
  }
}

