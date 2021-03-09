resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
    labels = {
      name = "logging"
    }
  }
}


# Utility dns record for people using vpn
resource "kubernetes_service" "elasticsearch" {
  metadata {
    namespace = kubernetes_namespace.logging.metadata[0].name
    name      = "kibana"
  }
  spec {
    type          = "ExternalName"
    external_name = data.aws_elasticsearch_domain.logging_cluster.endpoint
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
