
# Create a route53 zone
# resource "aws_route53_zone" "public" {
#   name = var.domain_name
# }

# Reference an existing route53 zone
data "aws_route53_zone" "public" {
  name = var.domain_name
}



# To use an ACM cert with CF it has to exist in us-east-1
provider "aws" {
  region = "us-east-1"
  alias  = "east1"
}

# Create an ACM cert for this domain
resource "aws_acm_certificate" "wildcard_cert" {
  provider    = aws.east1

  domain_name             = var.domain_name
  validation_method       = "DNS"
}

resource "aws_acm_certificate_validation" "wildcard_cert" {
  certificate_arn         = aws_acm_certificate.wildcard_cert.arn
  validation_record_fqdns = aws_route53_record.cert_validation.*.fqdn
}

# Route53 record to validate the certificate
resource "aws_route53_record" "cert_validation" {
  name            = aws_acm_certificate.wildcard_cert.domain_validation_options[0]["resource_record_name"]
  records         = [aws_acm_certificate.wildcard_cert.domain_validation_options[0]["resource_record_value"]]
  type            = "CNAME"
  allow_overwrite = true
  zone_id         = data.aws_route53_zone.public.zone_id
  ttl             = 300
}
