variable "region" {
  description = "AWS Region"
}

variable "environment" {
  description = "Environment"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
}

variable "external_dns_zone" {
  description = "Domain of R53 zone that external-dns will have access to"
}

variable "external_dns_owner_id" {
  description = "Unique id of the TXT record that external-dns will use to store state (can just be a uuid)"
}

variable "cert_manager_acme_environment" {
  default     = "production"
  description = "ACME (LetsEncrypt) Environment - only production creates valid certificates but it has lower rate limits"
}

variable "cert_manager_acme_registration_email" {
  description = "Email to associate with ACME account when registering with LetsEncrypt"
}
