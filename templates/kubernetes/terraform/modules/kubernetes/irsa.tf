# IRSA support: allow application specific policy via service-account and role

# application_policy_list is passed from main.tf as below:
  # application_policy_list = [
  #   {
  #     application     = "app1"
  #     namespace       = "piggycloud-me"
  #     policy          = data.aws_iam_policy_document.my_app
  #   },
  #   {
  #     application     = "app2"
  #     namespace       = "piggycloud-me"
  #     policy          = data.aws_iam_policy_document.my_app
  #   }
  #   # could be more here
  # ]

# Create a role using oidc to map service accounts
module "iam_assumable_role_irsa" {
  count                         = length(var.application_policy_list)
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.14.0"
  create_role                   = true
  role_name                     = "${var.project}-k8s-${var.environment}-${var.application_policy_list[count.index].application}"
  provider_url                  = replace(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.piggycloud_me[count.index].arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.application_policy_list[count.index].namespace}:${var.application_policy_list[count.index].application}"]
}

# Create policies
resource "aws_iam_policy" "irsa" {
  count       = length(var.application_policy_list)
  name_prefix = var.project
  description = "${var.project} policy for service account ${var.application_policy_list[count.index].application}"
  policy      = var.application_policy_list[count.index].policy.json
}

# Create kubernetes applications
resource "kubernetes_application" "irsa" {
  count         = length(var.application_policy_list)
  metadata {
    name        = var.application_policy_list[count.index].application
    namespace   = var.application_policy_list[count.index].namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_assumable_role_piggycloud_me[count.index].this_iam_role_arn
    }
  }
}
