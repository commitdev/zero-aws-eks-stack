# AWS policy documents for allowing console
data "aws_iam_policy_document" "console_allowed" {
  statement {
    sid       = "AllowConsolePasswordDisplay"
    effect    = "Allow"
    actions = [
      "iam:ListUsers",
    ]
    resources = ["arn:aws:iam::${local.account_id}:user/*"]
  }
  statement {
    sid     = "AllowManageOwnProfile"
    effect  = "Allow"
    actions = [
      "iam:GetLoginProfile",
      "iam:CreateLoginProfile",
      "iam:DeleteLoginProfile",
      "iam:UpdateLoginProfile",
    ]
    resources = ["arn:aws:iam::${local.account_id}:user/$${aws:username}"]
  }
}

resource "aws_iam_group" "console_allowed" {
  name  = "console-allowed"
}

resource "aws_iam_group_policy" "console_allowed" {
  name   = "AllowConsole"
  group  = aws_iam_group.console_allowed.name
  policy = data.aws_iam_policy_document.console_allowed.json
}
