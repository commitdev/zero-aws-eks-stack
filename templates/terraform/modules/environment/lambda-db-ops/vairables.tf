variable "project" {
  description = "The name of the project, mostly for tagging"
}

variable "environment" {
  description = "The environment (dev/staging/prod)"
}

variable "subnet_ids" {
  description = "Subnet IDs the lambda function is able to connect to inside the VPC"
  default     = []
  type        = list(string)
}
variable "security_group_ids" {
  description = "Security groups the lambda function is able to connect to inside the VPC"
  default     = []
  type        = list(string)
}
