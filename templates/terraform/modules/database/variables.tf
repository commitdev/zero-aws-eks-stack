variable "project" {
  description = "The name of the project, mostly for tagging"
}

variable "environment" {
  description = "The environment (development/staging/production)"
}

variable "vpc_id" {
  description = "The id of the VPC to create the DB in"
}

variable "allowed_security_group_id" {
  description = "The security group to allow access"
}

variable "instance_class" {
  description = "The AWS instance class of the db"
}

variable "storage_gb" {
  description = "The amount of storage to allocate for the db, in GB"
}

variable "database_engine" {
  description = "Which database engine to use, currently supports `postgres` or `mysql`"
}
