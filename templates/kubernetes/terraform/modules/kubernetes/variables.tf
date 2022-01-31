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

variable "external_dns_zones" {
  description = "Domains of R53 zones that external-dns and cert-manager will have access to"
  type        = list(string)
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
      var.logging_type == "cloudwatch" || var.logging_type == "kibana" || var.logging_type == "none"
    )
    error_message = "Invalid value. Valid values are cloudwatch, kibana, or none."
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
  type        = list(any)
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

variable "notification_service_enabled" {
  description = "If enabled, will install the Zero notification service in the cluster to enable easy implementation of notification via email, sms, push, etc."
  type        = bool
  default     = false
}

variable "notification_service_highly_available" {
  description = "If enabled, will make sure a minimum of 2 pods are running and use a horizontal pod autoscaler to make scale the number of pods based on CPU. Recommended for Production."
  type        = bool
  default     = true
}

variable "notification_service_twilio_phone_number" {
  description = "Twilio Phone Number is the Send from number for your SMS messages for the notification service"
  type        = string
  default     = ""
}

variable "cache_store" {
  description = "Cache store - redis or memcached"
  type        = string
  default     = "none"
}

variable "user_auth" {
  description = "a list of maps configuring oathkeeper instances"
  default     = []

  type = list(object({
    name                        = string
    frontend_service_domain     = string
    backend_service_domain      = string
    auth_namespace              = string
    kratos_secret_name          = string
    jwks_secret_name            = string
    user_auth_mail_from_address = string
    whitelisted_return_urls     = list(string)
    cookie_signing_secret_key   = string
    kratos_values_override      = map(any)
    oathkeeper_values_override  = map(any)
  }))
}

variable "user_auth_dev_env_enabled" {
  description = "When enabled will provision Kratos and Oathkeeper Rules for dev environment"
  type        = bool
  default     = false
}

variable "dev_user_auth_frontend_domain" {
  description = "Frontend domain used for local development with dev env"
  type        = string
  default     = "127.0.0.1:3000"
}

variable "nginx_ingress_replicas" {
  description = "The number of ingress controller pods to run in the cluster. Production environments should not have less than 2"
  type        = number
  default     = 2
}

variable "enable_node_termination_handler" {
  description = "The Node Termination Handler should be enabled when using spot instances in your cluster, as it is responsible for gracefully draining a node that is due to be terminated. It can also be used to cleanly handle scheduled maintenance events on On-Demand instances, though it runs as a daemonset, so will run 1 pod on each node in your cluster"
  type        = bool
  default     = false
}

variable "create_database_service" {
  description = "For ease of use, create an 'ExternalName' type service called 'database' in the application's namespace that points at the app db. The db will be auto-discovered based on its name"
  type        = bool
  default     = true
}

variable "k8s_role_mapping" {
  type = list(object({
    name = string
    policies  = list(map(list(string)))
    groups    = list(string)
  }))
  description = "List of Kubernetes Policies and Groups to create and map to IAM roles"
}

variable "assumerole_account_ids" {
  description = "AWS account IDs that will be allowed to assume the roles we are creating. If left blank, the 'allowed_account_ids' will be used"
  type        = list(string)
  default     = []
}
