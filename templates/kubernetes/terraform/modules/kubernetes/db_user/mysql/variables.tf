variable "namespace" {
  description = "The name of the project"
}

variable "db_endpoint" {
  type        = string
  description = "database server endpoint eg. host:port"
}

variable "db_host" {
  type        = string
  description = "database server hostname"
}

variable "db_master_user" {
  type        = string
  description = "database server master user"
}

variable "db_master_password" {
  type        = string
  description = "database server master password"
}

variable "db_name" {
  type        = string
  description = "database name"
}

variable "db_app_user" {
  type        = string
  description = "database appliaction user name"
}

variable "db_app_password" {
  type        = string
  description = "database appliaction user password"
}
