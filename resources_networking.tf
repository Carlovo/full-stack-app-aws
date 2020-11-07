module "certificate_and_validation" {
  count = var.alternate_domain_name == "" ? 0 : 1

  source = "./modules/certificate_and_validation"

  # CloudFront accepts only ACM certificates from US-EAST-1
  providers = {
    aws = aws.useast1
  }

  domain_names = local.alternate_domain_names
  zone_id      = data.aws_route53_zone.selected[0].zone_id
}

resource "aws_cloudfront_distribution" "minimal_distribution" {
  origin {
    domain_name = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.frontend_bucket.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.minimal_cloudfront_identity.cloudfront_access_identity_path
    }
  }

  aliases             = local.alternate_domain_names
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.frontend_bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 900
    max_ttl                = 3600
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # conditional nested blocks are not supported by Terraform, therefore this hack
  dynamic "viewer_certificate" {
    for_each = var.alternate_domain_name == "" ? [1] : []
    content {
      cloudfront_default_certificate = true
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.alternate_domain_name == "" ? [] : [1]
    content {
      acm_certificate_arn = module.certificate_and_validation[0].acm_certificate_arn
      ssl_support_method  = "sni-only"
    }
  }
}

module "alias_a_records" {
  for_each = toset(local.alternate_domain_names)

  source = "./modules/route53_alias_a_records"

  dns_record_name = each.key

  hosted_zone_id       = data.aws_route53_zone.selected[0].zone_id
  alias_domain_name    = aws_cloudfront_distribution.minimal_distribution.domain_name
  alias_hosted_zone_id = aws_cloudfront_distribution.minimal_distribution.hosted_zone_id
}
