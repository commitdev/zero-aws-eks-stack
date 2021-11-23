locals {
  ssm_parameter_name_prefix = "/${var.project}/sam/${var.environment}/"
  secret_manager_name_prefix = "/${var.project}/sam/${var.environment}/"
}
resource "random_id" "cookie_signing_secret" {
  keepers = {
    # Generate a new id each time we switch to a new auth0_client_id
    project = "${var.project}-${var.environment}"
  }
  byte_length = 16
}


module "serverless_application_secrets" {
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name   = "${local.secret_manager_name_prefix}application"
  type   = "map"
  values = {
    STRIPE_API_SECRET_KEY  = ""
    COOKIE_SIGNING_SECRET = random_id.cookie_signing_secret.b64_std
  }
  tags   = {  app : var.project, env : var.environment }
}

module "parameter_hostedzoneid" {
  source  = "../ssm_parameter"

  name   = "${local.ssm_parameter_name_prefix}hosted-zone-id"
  type   = "String"
  value = module.sam_gateway_cert.route53_zone_id
  tags   = {  auth : var.project, env : var.environment }
}

module "parameter_gatewaycertarn" {
  source  = "../ssm_parameter"

  name   = "${local.ssm_parameter_name_prefix}gateway-cert-arn"
  type   = "String"
  value = module.sam_gateway_cert.certificate_arn
  tags   = {  auth : var.project, env : var.environment }
}
