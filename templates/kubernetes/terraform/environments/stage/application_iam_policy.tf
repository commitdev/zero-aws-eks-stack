
# define policy documents for applications
# sample policies
data "aws_iam_policy_document" "resource_access_app1" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
    ]
    resources = ["arn:aws:ec2:::stage-*"]
  }
  # can be more statements here
}

data "aws_iam_policy_document" "resource_access_app2" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
    ]
    resources = ["arn:aws:ec2:::stag-*"]
  }
  # can be more statements here
}
