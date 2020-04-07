variable "region" {
  description = "The AWS region"
}

variable "zone_name" {
  description = "Domains of the Route53 hosted zone"
  type = string
}

variable "domain_names" {
  description = "Domains to create an ACM Cert for"
  type = list(string)
}
