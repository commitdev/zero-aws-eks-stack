# New managed elasticsearch infra for EKS
# After creating the infra, run the manifest in kubernetes/monitoring/ to set up fluentd
module "elasticsearch" {
  source                  = "cloudposse/elasticsearch/aws"
  version                 = "0.20.4"
  namespace               = var.project
  stage                   = var.environment
  name                    = "logging"
  security_groups         = var.security_groups
  vpc_id                  = var.vpc_id
  subnet_ids              = var.subnet_ids
  zone_awareness_enabled  = (length(var.subnet_ids) > 1)
  availability_zone_count = length(var.subnet_ids)
  elasticsearch_version   = var.elasticsearch_version
  instance_type           = var.instance_type
  instance_count          = var.instance_count
  ebs_volume_size         = var.ebs_volume_size_in_gb
  encrypt_at_rest_enabled = !can(regex("(?i)^(M3|R3|T2)", var.instance_type)) # These previous-generation instance types can't support encryption at rest
  iam_actions             = ["es:*"]
  iam_role_arns           = ["*"]

  create_iam_service_linked_role = var.create_service_role

  log_publishing_application_enabled = var.enable_cluster_logging
  log_publishing_index_enabled       = var.enable_cluster_logging
  log_publishing_search_enabled      = var.enable_cluster_logging

  log_publishing_application_cloudwatch_log_group_arn = aws_cloudwatch_log_group.application_group.arn
  log_publishing_index_cloudwatch_log_group_arn       = aws_cloudwatch_log_group.index_group.arn
  log_publishing_search_cloudwatch_log_group_arn      = aws_cloudwatch_log_group.search_group.arn

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }
}

resource "aws_cloudwatch_log_group" "application_group" {
  name = "/aws/aes/domains/${var.project}-${var.environment}-logging/application-logs"
}

resource "aws_cloudwatch_log_group" "index_group" {
  name = "/aws/aes/domains/${var.project}-${var.environment}-logging/index-logs"
}

resource "aws_cloudwatch_log_group" "search_group" {
  name = "/aws/aes/domains/${var.project}-${var.environment}-logging/search-logs"
}

data "aws_iam_policy_document" "elasticsearch_log_publishing_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = ["arn:aws:logs:*"]

    principals {
      identifiers = ["es.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "elasticsearch_log_publishing_policy" {
  policy_document = data.aws_iam_policy_document.elasticsearch_log_publishing_policy.json
  policy_name     = "elasticsearch_log_publishing_policy"
}

# TODO : Add internal domain, VPC access
# resource "aws_route53_record" "kibana_cname" {
#   zone_id = aws_route53_zone.internal_domain.zone_id

#   name    = "kibana.${var.internal_domain}"
#   type    = "CNAME"
#   ttl     = "300"
#   records = [split("/", module.elasticsearch.kibana_endpoint)[0]] # TODO : check this. Was a workaround that may not be necessary after module upgrade
# }

