locals {
  cert_manager_namespace   = "kube-system"
  cert_manager_version     = "0.14.2"
  cluster_issuer_name      = var.cert_manager_use_production_acme_environment ? "clusterissuer-letsencrypt-production" : "clusterissuer-letsencrypt-production"
  cert_manager_acme_server = var.cert_manager_use_production_acme_environment ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"
}

# Reference an existing route53 zone
data "aws_route53_zone" "public" {
  name = var.external_dns_zone
}

# Cert-manager CRD manifest
# https://github.com/jetstack/cert-manager/releases/download/v0.14.2/cert-manager.crds.yaml
data "local_file" "cert_manager" {
  filename = "${path.module}/files/cert-manager.crds.yaml"
}

# Install the cert manager Custom Resource Definitions (this can't be done via helm/terraform)
resource "null_resource" "cert_manager" {
  triggers = {
    manifest_sha1 = "${sha1("${data.local_file.cert_manager.content}")}"
  }
  provisioner "local-exec" {
    command = "kubectl apply --validate=false -f ${path.module}/files/cert-manager.crds.yaml"
  }
}


# Cert-manager issuer manifest
data "template_file" "cert_manager_issuer" {
  template = "${file("${path.module}/files/cert_manager_issuer.yaml.tpl")}"
  vars = {
    name                    = local.cluster_issuer_name
    environment             = var.environment
    acme_registration_email = var.cert_manager_acme_registration_email
    acme_server             = local.cert_manager_acme_server
    region                  = var.region
    hosted_zone_id          = data.aws_route53_zone.public.zone_id
  }
}

# Manually kubectl apply the cert-manager issuer, as the kubernetes terraform provider
# does not have support for custom resources.
resource "null_resource" "cert_manager_issuer" {
  triggers = {
    manifest_sha1 = "${sha1("${data.template_file.cert_manager_issuer.rendered}")}"
  }
  provisioner "local-exec" {
    command = "kubectl apply -f - <<EOF\n${data.template_file.cert_manager_issuer.rendered}\nEOF"
  }
  depends_on = [null_resource.cert_manager]
}

data "helm_repository" "jetstack" {
  name = "jetstack"
  url  = "https://charts.jetstack.io"
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = data.helm_repository.jetstack.metadata[0].name
  chart      = "cert-manager"
  version    = local.cert_manager_version
  namespace  = local.cert_manager_namespace
  set_string {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value =  module.iam_assumable_role_cert_manager.this_iam_role_arn
  }
  set_string {
    name  = "podAnnotations.eks\\.amazonaws\\.com/role-arn"
    value =  module.iam_assumable_role_cert_manager.this_iam_role_arn
  }
  set {
    name  = "securityContext.fsGroup"
    value = "1001"
  }
}


# Create a role using oidc to map service accounts
module "iam_assumable_role_cert_manager" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.6.0"
  create_role                   = true
  role_name                     = "<% .Name %>-k8s-${var.environment}-cert-manager"
  provider_url                  = replace(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.cert_manager.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.cert_manager_namespace}:cert-manager"]
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

    resources = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.public.zone_id}"]
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
