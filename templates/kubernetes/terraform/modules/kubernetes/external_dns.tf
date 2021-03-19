# Create a role using oidc to map service accounts
module "iam_assumable_role_external_dns" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v3.12.0"
  create_role                   = true
  role_name                     = "${var.project}-k8s-${var.environment}-external-dns"
  provider_url                  = replace(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:external-dns"]
}

resource "aws_iam_policy" "external_dns" {
  name_prefix = "external-dns"
  description = "EKS external-dns policy for cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.external_dns_policy_doc.json
}

data "aws_iam_policy_document" "external_dns_policy_doc" {
  statement {
    sid    = "k8sExternalDnsRead"
    effect = "Allow"

    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "k8sExternalDnsWrite"
    effect = "Allow"

    actions = ["route53:ChangeResourceRecordSets"]

    // data.aws_route53_zone.zones declared in ./cert-manager.tf
    resources = [for index, domain in var.external_dns_zones : "arn:aws:route53:::hostedzone/${data.aws_route53_zone.zones[index].zone_id}"]
  }
}

resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_assumable_role_external_dns.this_iam_role_arn
    }
  }
}

resource "kubernetes_cluster_role" "external_dns" {
  metadata {
    name = "external-dns"
  }
  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["pods", "services"]
  }
  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["extensions"]
    resources  = ["ingresses"]
  }
  rule {
    verbs      = ["list"]
    api_groups = [""]
    resources  = ["nodes"]
  }
  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["endpoints"]
  }
}

resource "kubernetes_cluster_role_binding" "external_dns" {
  metadata {
    name = "external-dns"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "external-dns"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "external-dns"
  }
}

resource "kubernetes_deployment" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = "external-dns",
      }
    }
    template {
      metadata {
        labels = {
          "app" = "external-dns",
        }
      }
      spec {
        container {
          name  = "external-dns"
          image = "registry.opensource.zalan.do/teapot/external-dns:latest"
          args = concat([
            "--source=ingress",
            "--source=service",
            "--provider=aws",
            "--aws-zone-type=public",
            "--policy=upsert-only", # Prevent ExternalDNS from deleting any records
            "--registry=txt",
            "--txt-owner-id=${var.cluster_name}", # ID of txt record to manage state
            "--aws-batch-change-size=2",          # Set the batch size to 2 so that a single record failure won't block other updates
            ],
            # Give access only to the specified zones
          [for domain in var.external_dns_zones : "--domain-filter=${domain}"])
        }

        security_context {
          fs_group = 65534
        }

        service_account_name            = "external-dns"
        automount_service_account_token = true
      }
    }
  }
}
