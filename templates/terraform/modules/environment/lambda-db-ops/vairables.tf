variable "project" {
  description = "The name of the project, mostly for tagging"
}

variable "environment" {
  description = "The environment (dev/staging/prod)"
}

variable "subnet_ids" {
  default = []
  type     = list(string)
}
variable "security_group_ids" {
  default = []
  type     = list(string)
}
