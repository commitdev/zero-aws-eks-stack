data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

# Create a role using oidc to map service accounts
module "iam_assumable_role_cloudwatch" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.14.0"
  create_role                   = true
  role_name                     = "<% .Name %>-k8s-${var.environment}-cloudwatch"
  provider_url                  = replace(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns              = [data.aws_iam_policy.CloudWatchAgentServerPolicy.arn]
  oidc_fully_qualified_subjects = [ "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent" ]
}

# Create a role using oidc to map service accounts
module "iam_assumable_role_fluentd" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.14.0"
  create_role                   = true
  role_name                     = "<% .Name %>-k8s-${var.environment}-fluentd"
  provider_url                  = replace(data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns              = [data.aws_iam_policy.CloudWatchAgentServerPolicy.arn]
  oidc_fully_qualified_subjects = [ "system:serviceaccount:amazon-cloudwatch:fluentd" ]
}


data "aws_iam_policy" "CloudWatchAgentServerPolicy" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create amazon-cloudwatch kubernetes namespace for fluentd/cloudwatchagent
resource "kubernetes_namespace" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
    labels = {
      name = "amazon-cloudwatch"
    }
  }
}
