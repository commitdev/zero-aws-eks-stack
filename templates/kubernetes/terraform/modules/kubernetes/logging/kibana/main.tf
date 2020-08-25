resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
    labels = {
      name = "logging"
    }
  }
}



# # Kibana ingress - Allows us to modify the path, but proxies out to elasticsearch
# resource "kubernetes_ingress" "kibana_ingress" {
#   metadata {
#     name      = "kibana"
#     namespace = "logging"
#     annotations = {
#       "kubernetes.io/ingress.class"                    = "nginx-internal"
#       "nginx.ingress.kubernetes.io/proxy-body-size"    = "32m"
#       "nginx.ingress.kubernetes.io/rewrite-target"     = "/_plugin/kibana/$1"
#       "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
#     }
#   }

#   spec {
#     rule {
#       host = "kibana.${var.internal_domain}"

#       http {
#         path {
#           path = "/(.*)"
#           backend {
#             service_name = "elasticsearch"
#             service_port = 80
#           }
#         }

#         path {
#           path = "/_plugin/kibana/(.*)"
#           backend {
#             service_name = "elasticsearch"
#             service_port = 80
#           }
#         }
#       }
#     }

#   depends_on = [kubernetes_namespace.logging]
# }

# # ExternalName service allowing us to refer to elasticsearch
# resource "kubernetes_service" "kibana_service" {
#   metadata {
#     name      = "elasticsearch"
#     namespace = "logging"
#   }
#   spec {
#     type          = "ExternalName"
#     external_name = "es-eks.${var.internal_domain}"
#   }
#   depends_on = [kubernetes_namespace.logging]
# }


# # Create prometheus exporter to gather metrics about the elasticsearch cluster
# resource "helm_release" "elasticsearch_prometheus_exporter" {
#   name       = "elasticsearch-exporter"
#   repository = "stable"
#   chart      = "elasticsearch-exporter"
#   version    = "3.4.0"
#   namespace  = "monitoring"
#   set {
#     name  = "es.uri"
#     value = "http://elasticsearch.logging.svc.cluster.local"
#   }
#   set {
#     name  = "serviceMonitor.enabled"
#     value = "true"
#   }
# }
