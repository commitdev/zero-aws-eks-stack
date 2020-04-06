variable "project" {
  description = "The name of the project, mostly for tagging"
}

variable "buckets" {
  description = "S3 hosting buckets"
  type = set(string)
}

variable "certificate_arn" {
  description = "ARN of the certificate we created for the assets domain"
}

variable "route53_zone_id" {
  description = "ID of the Route53 zone to create a record in"
  type = string
}
