variable "project" {
  description = "The name of the project, mostly for tagging"
}

variable "environment" {
  description = "The environment (dev/staging/prod)"
}

variable "frontend_domain" {
  description = "Frontend domain"
}

variable "backend_domain" {
  description = "Backend domain"
}

variable "secret_name" {
  description = "For terraform to use auth0 tenant api"
}
