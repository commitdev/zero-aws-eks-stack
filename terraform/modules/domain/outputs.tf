output "route53_zone_id" {
  description = "Identifier of the created Route53 Zone"
  value       = aws_route53_zone.public.zone_id
}

output "certificate_arn" {
  description = "The ARN of the created certificate"
  value       = aws_acm_certificate.wildcard_cert.arn
}
