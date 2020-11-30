variable "region" {
  description = "AWS Region"
}

variable "project" {
  description = "The name of the project"
}

variable "allowed_account_ids" {
  description = "The IDs of AWS accounts for this project, to protect against mistakenly applying to the wrong env"
  type        = list(string)
}

variable "environment" {
  description = "Environment (prod/stage)"
}

variable "random_seed" {
  description = "A randomly generated string to prevent collisions of resource names - should be unique within an AWS account"
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

variable "cert_manager_use_production_acme_environment" {
  description = "ACME (LetsEncrypt) Environment - only production creates valid certificates but it has lower rate limits than staging"
  type        = bool
  default     = true
}

variable "cert_manager_acme_registration_email" {
  description = "Email to associate with ACME account when registering with LetsEncrypt"
}

variable "logging_type" {
  description = "Which application logging mechanism to use (cloudwatch, kibana)"
  type        = string
  default     = "cloudwatch"

  validation {
    condition = (
      var.logging_type == "cloudwatch" || var.logging_type == "kibana"
    )
    error_message = "Invalid value. Valid values are cloudwatch or kibana."
  }
}

variable "metrics_type" {
  description = "Which application metrics mechanism to use (prometheus, none)"
  type        = string
  default     = "none"

  validation {
    condition = (
      var.metrics_type == "prometheus" || var.metrics_type == "none"
    )
    error_message = "Invalid value. Valid values are none or prometheus."
  }
}

variable "application_policy_list" {
  description = "Application policies"
  type        = list
  default     = []
}

variable "vpn_server_address" {
  description = "VPN server address"
  type        = string
}

variable "vpn_client_publickeys" {
  type        = list(tuple([string, string, string]))
  description = "VPN List of client name, IP and public key"
}

variable "cf_signing_enabled" {
  type        = bool
  description = "Enable CloudFront signed URLs"
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
  default     = ""
}

variable "internal_domain" {
  description = "Internal domain to create records in"
  type        = string
  default     = ""
}

variable "auth_enabled" {
  description = "Domain to use for authentication"
  type        = string
  default     = ""
}

variable "auth_domain" {
  description = "Domain to use for authentication"
  type        = string
  default     = ""
}

variable "backend_service_domain" {
  description = "Domain of the backend service"
  type        = string
  default     = ""
}

variable "frontend_service_domain" {
  description = "Domain of the frontend"
  type        = string
  default     = ""
}

variable "user_auth_mail_from_address" {
  description = "Mail from the user management system will come from this address"
  type        = string
  default     = ""
}
