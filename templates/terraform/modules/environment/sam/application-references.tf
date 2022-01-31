locals {
  ssm_parameter_name_prefix = "/${var.project}/sam/${var.environment}/"
  secret_manager_name_prefix = "/${var.project}/sam/${var.environment}/"
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

## Reason this is not in a comma separated stringList is because cloudformation
## executes !Split before !Sub and ressolve for variables
## so when we try to !Split and !Sub it will be a string with all the values
module "parameter_gateway_vpc_subnets_values" {
  source  = "../ssm_parameter"
  count = length(var.vpc_subnets)

  name   = "${local.ssm_parameter_name_prefix}vpc-subnet-${count.index}"
  type   = "String"
  value   = var.vpc_subnets[count.index]
  tags   = {  auth : var.project, env : var.environment }
}

module "parameter_gateway_security_group_id" {
  source  = "../ssm_parameter"

  name   = "${local.ssm_parameter_name_prefix}security-group-id"
  type   = "String"
  value = var.security_group_id
  tags   = {  auth : var.project, env : var.environment }
}

module "parameter_gateway_lambda_execution_role_arn" {
  source  = "../ssm_parameter"

  name   = "${local.ssm_parameter_name_prefix}lambda-execution-role-arn"
  type   = "String"
  value  = aws_iam_role.lambda_execution_role.arn
  tags   = {  auth : var.project, env : var.environment }
}

