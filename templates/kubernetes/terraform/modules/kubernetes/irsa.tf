# IRSA support: allow backend service to have a specific policy via service-account and role

# application_policy_list is passed from main.tf as below:
  # application_policy_list = [
  #   {
  #     service_account = "backend-service"
  #     namespace       = "my-app"
  #     policy          = data.aws_iam_policy_document.resource_access_app1
  #   }
  #   # could be more here
  # ]

# Create a role using oidc to map service accounts
module "iam_assumable_role_irsa" {
  count                         = length(var.application_policy_list)
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.14.0"
  create_role                   = true
  role_name                     = "${var.project}-k8s-${var.environment}-${var.application_policy_list[count.index].service_account}"
  provider_url                  = replace(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.irsa[count.index].arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.application_policy_list[count.index].namespace}:${var.application_policy_list[count.index].service_account}"]
}

# Create policies
resource "aws_iam_policy" "irsa" {
  count       = length(var.application_policy_list)
  name_prefix = "${var.project}-k8s-${var.environment}"
  description = "policy for service account ${var.application_policy_list[count.index].namespace}:${var.application_policy_list[count.index].service_account}"
  policy      = var.application_policy_list[count.index].policy.json
}

# Create kubernetes service account
resource "kubernetes_service_account" "irsa" {
  count         = length(var.application_policy_list)
  metadata {
    name        = var.application_policy_list[count.index].service_account
    namespace   = var.application_policy_list[count.index].namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_assumable_role_irsa[count.index].this_iam_role_arn
    }
  }
}
