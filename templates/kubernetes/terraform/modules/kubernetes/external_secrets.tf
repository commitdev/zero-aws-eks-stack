locals {
  external_secrets_namespace = "kube-system"

  // Set / expose poller interval?
  external_secrets_helm_values = {
    nameOverride : "external-secrets"
    serviceMonitor : {
      enabled : (var.metrics_type == "prometheus")
      namespace : "metrics"
    }
    serviceAccount : {
      name : "external-secrets"
      annotations : {
        "eks.amazonaws.com/role-arn" : module.iam_assumable_role_external_secrets.this_iam_role_arn
      }
    }
    securityContext : {
      fsGroup : 65534
    }
    env : {
      AWS_REGION : var.region
      LOG_LEVEL : "warn" # use "info" to see all polling events
      # Each request to Secrets Manager has a small cost ($0.05 per 10,000 API calls) so a longer interval will reduce the number of calls but it will take longer to get updated secret values
      POLLER_INTERVAL_MILLISECONDS : 15000
    }
  }
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://external-secrets.github.io/kubernetes-external-secrets/"
  chart      = "kubernetes-external-secrets"
  version    = "7.2.1"
  namespace  = local.external_secrets_namespace
  values     = [jsonencode(local.external_secrets_helm_values)]
}

# Create a role using oidc to map service accounts
module "iam_assumable_role_external_secrets" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v3.15.0"
  create_role                   = true
  role_name                     = "${var.project}-k8s-${var.environment}-external-secrets"
  provider_url                  = replace(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.external_secrets.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.external_secrets_namespace}:external-secrets"]
}

resource "aws_iam_policy" "external_secrets" {
  name_prefix = "kubernetes-external-secrets"
  description = "Kubernetes External Secrets Policy"
  policy      = data.aws_iam_policy_document.external_secrets_policy_doc.json
}

data "aws_iam_policy_document" "external_secrets_policy_doc" {
  statement {
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:${var.region}:*:secret:${var.project}/kubernetes/${var.environment}/*"]

    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
  }
}
