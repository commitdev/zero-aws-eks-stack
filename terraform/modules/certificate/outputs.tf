output "route53_zone_id" {
  description = "Identifier of the Route53 Zone"
  value       = data.aws_route53_zone.public.zone_id
}

output "certificate_arns" {
  description = "The ARNs of the created certificates, keyed by domain name"
  value       = zipmap(aws_acm_certificate.cert[*].domain_name, aws_acm_certificate.cert[*].arn)
}

output "certificate_validations" {
  description = "The ids of the certificate validations. Provided as a dependency so dependents can wait until the cert is actually valid"
  value       = aws_acm_certificate_validation.cert[*].id
}
