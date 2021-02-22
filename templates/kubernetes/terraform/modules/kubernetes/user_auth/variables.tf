variable "project" {
  description = "The name of the project"
}

variable "auth_domain" {
  description = "Domain to use for authentication"
  type        = string
  default     = ""
}

variable "auth_namespace" {
  description = "Namespace to use for auth resources"
  type        = string
  default     = "user-auth"
}

variable "k8s_local_exec_context" {
  description = "parameters for kubectl to target k8s cluster"
  type = string
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
variable "jwks_secret_name" {
  description = "jwks_secret_name"
  type        = string
  default     = ""
}
