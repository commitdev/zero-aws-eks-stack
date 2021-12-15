locals {
  cert_manager_version     = "1.4.0"
  cluster_issuer_name      = var.cert_manager_use_production_acme_environment ? "clusterissuer-letsencrypt-production" : "clusterissuer-letsencrypt-staging"
  cert_manager_acme_server = var.cert_manager_use_production_acme_environment ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"

  # Enable the HTTP-01 challenge provider to resolve a challenge through the ingress
  cluster_issuer_http = yamlencode({
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = local.cluster_issuer_name
    }
    "spec" = {
      "acme" = {
        "email" = var.cert_manager_acme_registration_email
        "privateKeySecretRef" = {
          "name" = "clusterissuer-letsencrypt-${var.environment}-secret" # Name of a secret used to store the ACME account private key
        }
        "server" = local.cert_manager_acme_server # Email address used for ACME registration
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "class" = "nginx"
              }
            }
          },
        ]
      }
    }
  })

  # Create solver records for each domain
  dns_solvers = [for index, domain in var.external_dns_zones : {
    "dns01" = {
      "route53" = {
        "hostedZoneID" = data.aws_route53_zone.zones[index].zone_id
        "region"       = var.region
      }
    }
    "selector" = {
      "dnsZones" = [
        domain,
      ]
    }
    }
  ]

  # Enable the DNS-01 challenge provider to resolve a challenge by creating route53 records
  cluster_issuer_dns = yamlencode({
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "${local.cluster_issuer_name}-dns"
    }
    "spec" = {
      "acme" = {
        "email" = var.cert_manager_acme_registration_email # Email address used for ACME registration
        "privateKeySecretRef" = {
          "name" = "clusterissuer-letsencrypt-${var.environment}-secret" # Name of a secret used to store the ACME account private key
        }
        "server"  = local.cert_manager_acme_server
        "solvers" = local.dns_solvers
      }
    }
  })
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# Reference an existing route53 zone
data "aws_route53_zone" "zones" {
  count = length(var.external_dns_zones)
  name  = var.external_dns_zones[count.index]
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = local.cert_manager_version
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_assumable_role_cert_manager.this_iam_role_arn
  }
  set {
    name  = "securityContext.fsGroup"
    value = "1001"
  }
  set {
    name  = "installCRDs"
    value = true
  }
  set {
    name  = "prometheus.enabled"
    value = var.metrics_type == "prometheus"
  }
  set {
    name  = "prometheus.servicemonitor.enabled"
    value = var.metrics_type == "prometheus"
  }
  set {
    name  = "prometheus.servicemonitor.labels.app"
    value = var.metrics_type == "prometheus" ? "kube-prometheus-stack-prometheus" : ""
  }
  set {
    name  = "prometheus.servicemonitor.namespace"
    value = "metrics"
  }
}

# Manually kubectl apply the cert-manager issuers, as the kubernetes terraform provider
# does not have support for custom resources.
resource "null_resource" "cert_manager_http_issuer" {
  triggers = {
    manifest_sha1 = sha1(local.cluster_issuer_http)
  }
  # local exec call requires kubeconfig to be updated
  provisioner "local-exec" {
    command = "kubectl apply ${local.k8s_exec_context} -f - <<EOF\n${local.cluster_issuer_http}\nEOF"
  }
  depends_on = [helm_release.cert_manager, kubernetes_config_map.aws_auth, aws_iam_role.access_assumerole, kubernetes_cluster_role_binding.access_role]
}

resource "null_resource" "cert_manager_dns_issuer" {
  triggers = {
    manifest_sha1 = sha1(local.cluster_issuer_dns)
  }
  # local exec call requires kubeconfig to be updated
  provisioner "local-exec" {
    command = "kubectl apply ${local.k8s_exec_context} -f - <<EOF\n${local.cluster_issuer_dns}\nEOF"
  }
  depends_on = [helm_release.cert_manager, kubernetes_config_map.aws_auth, aws_iam_role.access_assumerole, kubernetes_cluster_role_binding.access_role]
}

# Create a role using oidc to map service accounts
module "iam_assumable_role_cert_manager" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v3.12.0"
  create_role                   = true
  role_name                     = "${var.project}-k8s-${var.environment}-cert-manager"
  provider_url                  = replace(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.cert_manager.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${kubernetes_namespace.cert_manager.metadata[0].name}:cert-manager"]
}

resource "aws_iam_policy" "cert_manager" {
  name_prefix = "cert-manager"
  description = "EKS cert-manager policy for cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.cert_manager_policy_doc.json
}

data "aws_iam_policy_document" "cert_manager_policy_doc" {
  statement {
    sid    = "ListZones"
    effect = "Allow"

    actions = [
      "route53:ListHostedZonesByName"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ReadWriteRecordsInZone"
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]

    resources = [for zone in data.aws_route53_zone.zones : "arn:aws:route53:::hostedzone/${zone.zone_id}"]
  }

  statement {
    sid    = "GetChange"
    effect = "Allow"

    actions = [
      "route53:GetChange"
    ]

    resources = ["arn:aws:route53:::change/*"]
  }
}
