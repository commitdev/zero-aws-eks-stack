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
