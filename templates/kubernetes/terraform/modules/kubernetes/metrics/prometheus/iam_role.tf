
# Create a role using oidc to map service accounts
module "iam_assumable_role_irsa" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.14.0"
  create_role                   = true
  role_name                     = "${var.project}-k8s-${var.environment}-${kubernetes_namespace.metrics.metadata[0].name}-grafana"
  provider_url                  = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.grafana_irsa.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${kubernetes_namespace.metrics.metadata[0].name}:kube-prometheus-stack-grafana"]
}

# Create policies
resource "aws_iam_policy" "grafana_irsa" {
  name_prefix = "${var.project}-k8s-${var.environment}"
  description = "policy for service account ${kubernetes_namespace.metrics.metadata[0].name}:kube-prometheus-stack-grafana"
  policy      = data.aws_iam_policy_document.grafana.json
}

data "aws_iam_policy_document" "grafana" {
  statement {
    sid       = "AllowReadingMetricsFromCloudWatch"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricData",
    ]
  }

  statement {
    sid       = "AllowReadingLogsFromCloudWatch"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:DescribeLogGroups",
      "logs:GetLogGroupFields",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:GetQueryResults",
      "logs:GetLogEvents",
    ]
  }

  statement {
    sid       = "AllowReadingTagsInstancesRegionsFromEC2"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
    ]
  }

  statement {
    sid       = "AllowReadingResourcesForTags"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["tag:GetResources"]
  }
}
