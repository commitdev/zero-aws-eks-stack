// TODO : move to terrform-aws-zero

resource "aws_ssm_parameter" "string_parameter" {
  count       = var.type == "String" ? 1 : 0
  name        = var.name
  description = "The parameter description"
  type        = var.type
  value       = var.value

  tags        = var.tags
}

resource "aws_ssm_parameter" "stringlist_parameter" {
  count       = var.type == "StringList" ? 1 : 0
  name        = var.name
  description = "The parameter description"
  type        = var.type
  value       = join(",", var.values)

  tags        = var.tags
}
