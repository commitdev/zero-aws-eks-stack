
# define policy documents for backend services
# sample policies
data "aws_iam_policy_document" "resource_access_backendservice" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
    ]
    resources = ["arn:aws:ec2:::dev-*"]
  }
  # can be more statements here
}