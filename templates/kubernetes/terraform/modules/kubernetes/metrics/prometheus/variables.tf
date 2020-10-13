variable "project" {
  description = "The name of the project"
}

variable "region" {
  description = "AWS Region"
}

variable "environment" {
  description = "Environment"
}

variable "prometheus_retention_days" {
  description = "Days of retention for Prometheus stats"
  type        = number
  default     = 90
}

variable "prometheus_storage_capacity" {
  description = "Storage capacity for Prometheus stat data in Gibibytes"
  type        = number
  default     = 50
}

variable "internal_domain" {
  description = "Internal domain in which to create an ingress"
  type        = string
  default     = ""
}
