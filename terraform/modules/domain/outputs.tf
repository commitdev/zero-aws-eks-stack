output "route53_zone_id" {
  description = "Identifier of the Route53 Zone"
  value       = data.aws_route53_zone.public.zone_id
}

output "certificate_arn" {
  description = "The ARN of the created certificate"
  value       = aws_acm_certificate.wildcard_cert.arn
}
