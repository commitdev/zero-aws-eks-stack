# define policy documents for developer policy
data "aws_iam_policy_document" "developer_access" {
  # EKS
  statement {
    effect = "Allow"
    actions = [
      "eks:List*",
      "eks:Describe*"
    ]
    resources = ["arn:aws:eks:::cluster/<% .Name %>-prod*"]
  }
  # ECR
  statement {
    effect = "Allow"
    actions = [
      "ecr:DescribeImages",
      "ecr:DescribeRepositories"
    ]
    resources = ["*"]
  }
  # S3
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::<% .Name %>-prod*"]
  }
}
