variable "project" {
  description = "The name of the project, mostly for tagging"
}

variable "environment" {
  description = "The environment (staging/prod)"
}

variable "frontend_domain" {
  description = "Backend domain to whitelist in Auth0 for CORS and Allowed Logout URLs"
}

variable "backend_domain" {
  description = "Backend domain to whitelist in Auth0 for callbacks"
}

variable "secret_name" {
  description = "For terraform to use Auth0 tenant api to create clients, these credentials should have API create/manage clients permissions "
}
