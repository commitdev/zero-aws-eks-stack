// TODO : move to terrform-aws-zero

variable "name" {
  description = "The name of the paramter, for retrieving the value"
  type = string
}

variable "type" {
  description = "Type of parameter, can be string of StringList"
  type = string
  validation {
    condition = (
      var.type == "String" || var.type == "StringList"
    )
    error_message = "Invalid value. Must be one of (String, StringList)."
  }

}

variable "values" {
  description = "List of strings as value of parameter."
  type = list(string)
  default = []

}

variable "value" {
  description = "Value of parameter."
  type = string
  default = ""

}

variable "tags" {
  description = "Tags to include in the parameter"
  type        = map(any)
  default     = {}
}


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
