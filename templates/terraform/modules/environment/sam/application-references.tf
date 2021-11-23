locals {
  ssm_parameter_name_prefix = "/${var.project}/sam/${var.environment}/"
  secret_manager_name_prefix = "/${var.project}/sam/${var.environment}/"
}

module "serverless_application_secrets" {
  source  = "commitdev/zero/aws//modules/secret"
  version = "0.0.2"

  name   = "${local.secret_manager_name_prefix}application"
  type   = "map"
  values = {
    STRIPE_API_SECRET_KEY  = ""
  }
  tags   = {  app : var.project, env : var.environment }
}

module "parameter_hosted_zone_id" {
  source  = "../ssm_parameter"

  name   = "${local.ssm_parameter_name_prefix}hosted-zone-id"
  type   = "String"
  value = module.sam_gateway_cert.route53_zone_id
  tags   = {  auth : var.project, env : var.environment }
}

module "parameter_gateway_cert_arn" {
  source  = "../ssm_parameter"

  name   = "${local.ssm_parameter_name_prefix}gateway-cert-arn"
  type   = "String"
  value = module.sam_gateway_cert.certificate_arn
  tags   = {  auth : var.project, env : var.environment }
}
