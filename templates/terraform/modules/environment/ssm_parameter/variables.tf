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
