locals {
  # To prevent coupling to rds engine names
  type_map = {
    "postgres" : "postgres",
    "mysql" : "mysql",
  }
  db_type = local.type_map[data.aws_db_instance.database.engine]
}

resource "kubernetes_namespace" "user_auth" {
  count = var.auth_enabled ? 1 : 0
  metadata {
    name = "user-auth"
  }
}

#
resource "helm_release" "oathkeeper" {
  count      = var.auth_enabled ? 1 : 0
  name       = "oathkeeper"
  repository = "https://k8s.ory.sh/helm/charts"
  chart      = "oathkeeper"
  version    = "0.4.11"
  namespace  = kubernetes_namespace.user_auth[0].metadata[0].name

  values = [
    file("${path.module}/files/oathkeeper-values.yml")
  ]

  set {
    name  = "oathkeeper.config.mutators.id_token.config.issuer_url"
    value = "https://${var.backend_service_domain}"
  }

  # This will read the local jwks file and
  # Nope, this won't work. Need to create the secret OOB.
  # set {
  #   name  = "oathkeeper.mutatorIdTokenJWKs"
  #   value = file("${path.module}/files/id_token.jwks.json")
  # }

  set {
    name  = "oathkeeper.config.mutators.id_token.config.jwks_url"
    value = "http://zombism.ca/id_token.jwks.json"
  }

  set {
    name  = "oathkeeper.config.errors.handlers.redirect.config.to"
    value = "https://${var.backend_service_domain}/auth/login"
  }

  set {
    name  = "ingress.proxy.hosts[0].host"
    value = var.backend_service_domain
  }

  set {
    name  = "ingress.proxy.tls[0].hosts[0]"
    value = var.backend_service_domain
  }
}

#
resource "helm_release" "kratos" {
  count      = var.auth_enabled ? 1 : 0
  name       = "kratos"
  repository = "https://k8s.ory.sh/helm/charts"
  chart      = "kratos"
  version    = "0.4.11"
  namespace  = kubernetes_namespace.user_auth[0].metadata[0].name

  values = [
    file("${path.module}/files/kratos-values.yml")
  ]

  set {
    name = "kratos.config.dsn"
    # SQLite can be used for testing but there is no persistent storage set up for it
    value = "sqlite:///var/lib/sqlite/db.sqlite?_fk=true&mode=rwc"
    # value = "${local.db_type}://${kubernetes_service.app_db.metadata[0].name}.${kubernetes_service.app_db.metadata[0].namespace}"
  }

  set {
    name  = "kratos.config.serve.public.base_url"
    value = "https://${var.backend_service_domain}/.ory/kratos/public"
  }

  set {
    name  = "kratos.config.serve.admin.base_url"
    value = "https://admin.${var.auth_domain}"
  }

  set {
    name  = "ingress.public.hosts[0].host"
    value = var.auth_domain
  }

  set {
    name  = "ingress.public.tls[0].hosts[0]"
    value = var.auth_domain
  }

  set {
    name  = "ingress.admin.hosts[0].host"
    value = "admin.${var.auth_domain}"
  }

  set {
    name  = "ingress.admin.tls[0].hosts[0]"
    value = "admin.${var.auth_domain}"
  }
}
