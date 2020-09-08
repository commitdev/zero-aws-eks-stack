
# define policy documents for backend services
# sample policies
data "aws_iam_policy_document" "resource_access_backendservice" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
    ]
    resources = ["arn:aws:ec2:::stage-*"]
  }
  # can be more statements here

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = ["arn:aws:secretsmanager:us-west-2:864003660840:secret:vpn-stage*"]
  }
}
