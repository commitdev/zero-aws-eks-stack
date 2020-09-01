variable "sendgrid_enabled" {
  description = "If enabled, creates route53 entries for domain authentication"
  type  = bool
  default = false
}

variable "sendgrid_cnames" {
  description = "If enabled, creates route53 entries for domain authentication"
  type  = list(tuple([string, string]))
  default = []
}

variable "sendgrid_domain_id" {
  description = "domain_id from sendgrid api"
  type  = string
  default = ""
}
