variable "sendgrid_api_key" {
  description = "The Sendgrid API key to use for mailing, if necessary"
  default     = ""
}

variable "slack_api_key" {
  description = "The Slack API key to use with the notification service, if necessary"
  default     = ""
}

variable "twilio_account_id" {
  description = "The Twilio Account ID to use with the notification service, if necessary"
  default     = ""
}

variable "twilio_auth_token" {
  description = "The Twilio Auth Token to use with the notification service, if necessary"
  default     = ""
}

variable "productionAuth0TenantDoamin" {
  description = "Production Auth0 Tenant Domain"
  default     = ""
}
variable "productionAuth0TenantClientId" {
  description = "Production Auth0 Tenant Client ID"
  default     = ""
}
variable "productionAuth0TenantClientSecret" {
  description = "Production Auth0 Tenant Client Secret"
  default     = ""
}

variable "stagingAuth0TenantDoamin" {
  description = "Staging Auth0 Tenant Domain"
  default     = ""
}
variable "stagingAuth0TenantClientId" {
  description = "Staging Auth0 Tenant Client ID"
  default     = ""
}
variable "stagingAuth0TenantClientSecret" {
  description = "Staging Auth0 Tenant Client Secret"
  default     = ""
}
