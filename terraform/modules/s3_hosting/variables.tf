variable "project" {
  description = "The name of the project, mostly for tagging"
}

variable "environment" {
  description = "The environment (dev/staging/prod)"
}

variable "buckets" {
  description = "S3 hosting buckets"
  type = set(string)
}

variable "certificate_arns" {
  description = "ARN of the certificate we created for the assets domain, keyed by domain"
  type = map
}

variable "certificate_validations" {
  description = "Certificate validations, provided as a dependency so we can wait on the certs to be valid"
}

variable "route53_zone_id" {
  description = "ID of the Route53 zone to create a record in"
  type = string
}
