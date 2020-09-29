# AWS policy documents for console allowed
data "aws_iam_policy_document" "console_allowed" {
  statement {
    sid     = "AllowListUsers"
    effect  = "Allow"
    actions = [
      "iam:ListUsers",
    ]
    resources = ["*"]
  }

  statement {
    sid     = "AllowManageOwnProfile"
    effect  = "Allow"
    actions = [
      "iam:GetUser",
      "iam:CreateLoginProfile",
      "iam:DeleteLoginProfile",
      "iam:GetLoginProfile",
      "iam:UpdateLoginProfile",
    ]
    resources = ["arn:aws:iam::${local.account_id}:user/$${aws:username}"]
  }
}

resource "aws_iam_group" "console_allowed" {
  name  = "console-allowed"
}

resource "aws_iam_group_policy" "console_allowed" {
  name   = "RequireMFA"
  group  = aws_iam_group.console_allowed.name
  policy = data.aws_iam_policy_document.console_allowed.json
}
