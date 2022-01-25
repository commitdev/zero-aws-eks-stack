locals {
  # This secret is created by the /scripts/create-db-user.sh script and contains environment variables that will be pulled into a k8s secret automatically by external-secrets
  secrets_manager_secret_name = "${var.project}/application/${var.environment}/user-auth"
}


## Get generated JWKS content from secret
data "aws_secretsmanager_secret" "jwks_content" {
  count = length(var.user_auth)
  name  = var.user_auth[count.index].jwks_secret_name
}
data "aws_secretsmanager_secret_version" "jwks_content" {
  count     = length(data.aws_secretsmanager_secret.jwks_content)
  secret_id = data.aws_secretsmanager_secret.jwks_content[count.index].id
}

module "user_auth" {
  count   = length(var.user_auth)
  source  = "commitdev/zero/aws//modules/user_auth"
  version = "0.5.3"

  name                        = var.user_auth[count.index].name
  auth_namespace              = var.user_auth[count.index].auth_namespace
  create_namespace            = false
  kratos_secret_name          = var.user_auth[count.index].kratos_secret_name
  frontend_service_domain     = var.user_auth[count.index].frontend_service_domain
  backend_service_domain      = var.user_auth[count.index].backend_service_domain
  user_auth_mail_from_address = var.user_auth[count.index].user_auth_mail_from_address
  whitelisted_return_urls     = var.user_auth[count.index].whitelisted_return_urls
  jwks_content                = data.aws_secretsmanager_secret_version.jwks_content[count.index].secret_string
  cookie_signing_secret_key   = var.user_auth[count.index].cookie_signing_secret_key
  kubectl_extra_args          = local.k8s_exec_context
  external_secret_name        = local.secrets_manager_secret_name
  kratos_values_override      = lookup(var.user_auth[count.index], "kratos_values_override", {})
  oathkeeper_values_override  = lookup(var.user_auth[count.index], "oathkeeper_values_override", {})

  depends_on = [helm_release.external_secrets]
}

module "dev_user_auth" {
  count = var.user_auth_dev_env_enabled ? 1 : 0

  source  = "commitdev/zero/aws//modules/user_auth"
  version = "0.5.3"

  name                        = "development"
  auth_namespace              = "user-auth"
  create_namespace            = true
  kratos_secret_name          = var.project
  frontend_use_https          = false
  frontend_service_domain     = var.dev_user_auth_frontend_domain
  backend_service_domain      = "dev.${var.domain_name}"
  user_auth_mail_from_address = "noreply@${var.domain_name}"
  whitelisted_return_urls     = ["http://${var.dev_user_auth_frontend_domain}"]
  jwks_content                = "none"
  cookie_signing_secret_key   = "${var.project}-${var.environment}-${var.random_seed}"
  kubectl_extra_args          = local.k8s_exec_context
  external_secret_name        = "${var.project}/application/stage/user-auth"
  kratos_values_override      = {
    kratos = {
      config = {
        session = {
          cookie = {
            same_site = "None"
            domain = "dev.${var.domain_name}"
          }
        }
      }
    }
  }
  disable_oathkeeper          = true
}

resource "kubernetes_ingress" "dev_user_auth" {
  count = var.user_auth_dev_env_enabled ? 1 : 0

  metadata {
    name      = "dev-user-auth"
    namespace = "user-auth"
    annotations = {
      "kubernetes.io/ingress.class"                        = "nginx"
      "cert-manager.io/cluster-issuer"                     = "clusterissuer-letsencrypt-production"
      "nginx.ingress.kubernetes.io/enable-cors"            = "true"
      "nginx.ingress.kubernetes.io/cors-allow-origin"      = "http://${var.dev_user_auth_frontend_domain}"
      "nginx.ingress.kubernetes.io/cors-allow-credentials" =  "true"
    }
  }

  spec {
    rule {
      host = "dev.${var.domain_name}"
      http {
        path {
          path = "/"
          # Sharing Oathkeeper with stage instance
          backend {
            service_name = "oathkeeper-${var.user_auth[0].name}-proxy"
            service_port = "http"
          }
        }

      }
    }
    tls {
      secret_name = "dev-user-auth-tls-secret"
      hosts = [
        "dev.${var.domain_name}"
      ]
    }
  }
  depends_on = [module.user_auth]

}
