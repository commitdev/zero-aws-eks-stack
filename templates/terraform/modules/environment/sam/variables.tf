
variable "project" {
  description = "The name of the project, mostly for tagging"
}

variable "environment" {
  description = "The environment (dev/staging/prod)"
}

variable "region" {
  description = "The AWS region"
}

variable "random_seed" {
  description = "A randomly generated string to prevent collisions of resource names - should be unique within an AWS account"
}

variable "domain_name" {
  description = "Domain name for getting hosted zone and constructing endpoints"
}

variable "backend_domain" {
  description = "Backend domain"
}

variable "vpc_subnets" {
  description = "VPC subnets for Lambda functions to be deployed in"
  type = list(string)
}
variable "security_group_id" {
  description = "Security group that is allowed for RDS connection"
}
