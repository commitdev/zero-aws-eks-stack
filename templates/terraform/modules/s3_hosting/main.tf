locals {
  assets_access_identity = "${var.project}-${var.environment}-client-assets"
}

resource "aws_s3_bucket" "client_assets" {
  for_each = var.buckets

  // Our bucket's name is going to be the same as our site's domain name.
  bucket = each.value
  acl    = "private" // The contents will be available through cloudfront, they should not be accessible publicly
}

# Deny public access to this bucket
resource "aws_s3_bucket_public_access_block" "client_assets" {
  for_each = var.buckets

  bucket                  = aws_s3_bucket.client_assets[each.value].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Access identity for CF access to S3
resource "aws_cloudfront_origin_access_identity" "client_assets" {
  comment = local.assets_access_identity
}

# Policy to allow CF access to S3
data "aws_iam_policy_document" "assets_origin" {
  for_each = var.buckets

  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.client_assets[each.value].id}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.client_assets.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.client_assets[each.value].id}"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.client_assets.iam_arn]
    }
  }
}

# Attach the policy to the bucket
resource "aws_s3_bucket_policy" "client_assets" {
  for_each = var.buckets

  bucket = aws_s3_bucket.client_assets[each.value].id
  policy = data.aws_iam_policy_document.assets_origin[each.value].json
}

# Create the cloudfront distribution
resource "aws_cloudfront_distribution" "client_assets_distribution" {
  for_each = var.buckets

  // origin is where CloudFront gets its content from.
  origin {
      domain_name = aws_s3_bucket.client_assets[each.value].bucket_domain_name
      origin_id   = local.assets_access_identity
      s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.client_assets.cloudfront_access_identity_path
      }
    }

  // for single page applications, we need to respond with the index if file is missing
  custom_error_response {
    error_code = 404
    response_code = 200
    error_caching_min_ttl = 0
    response_page_path = "/index.html"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html" # Render this when you hit the root

  // All values are defaults from the AWS console.
  default_cache_behavior {
    target_origin_id       = local.assets_access_identity
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases = [
    each.value,
  ]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use our cert
  viewer_certificate {
      acm_certificate_arn      = var.certificate_arns[each.value]
      minimum_protocol_version = "TLSv1"
      ssl_support_method       = "sni-only"
    }
}

locals {
  # Find buckets that are the domain apex. These need to have A ALIAS records.
  rootDomainBuckets = [
    for bucket in var.buckets:
      bucket if length(regexall("\\.", bucket)) == 1
  ]

  # Find buckets that are subdomains. These can have CNAME records.
  subDomainBuckets = [
    for bucket in var.buckets:
      bucket if length(regexall("\\.", bucket)) > 1
  ]

}

# Root domains to point at CF
resource "aws_route53_record" "client_assets_root" {
  count = length(local.rootDomainBuckets)

  zone_id = var.route53_zone_id
  name    = local.rootDomainBuckets[count.index]
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.client_assets_distribution[local.rootDomainBuckets[count.index]].domain_name
    zone_id                = aws_cloudfront_distribution.client_assets_distribution[local.rootDomainBuckets[count.index]].hosted_zone_id
    evaluate_target_health = false
  }
}

# Subdomains to point at CF
resource "aws_route53_record" "client_assets_subdomain" {
  count = length(local.subDomainBuckets)

  zone_id = var.route53_zone_id
  name    = local.subDomainBuckets[count.index]
  type    = "CNAME"
  ttl     = "120"
  records = [aws_cloudfront_distribution.client_assets_distribution[local.subDomainBuckets[count.index]].domain_name]
}
