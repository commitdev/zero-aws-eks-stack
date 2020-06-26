variable "name" {
  default = ""
  description = "The name of the secret in Secrets Manager (only one of name or name_prefix can be specified)"
}

variable type {
  description = "The type of data to hold in this secret (map, string, random)"
}

variable "values" {
  description = "A map of keys/values to save as json for the secret if type is map"
  type = map
  default = {}
}

variable "value" {
  description = "A string value to save for the secret if type is string"
  default = ""
}

variable "random_length" {
  description = "The length of the generated string if type is random. Suitable for a db master password for example"
  default = 16
}

variable "tags" {
  description = "Tags to include in the secret"
  type = map
  default = {}
}
