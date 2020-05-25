output "cloudfront_distribution_ids" {
  description = "Identifiers of the created cloudfront distributions"
  value       = values(aws_cloudfront_distribution.client_assets_distribution)[*].id
}
