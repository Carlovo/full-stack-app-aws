# The resources below contain some count, for_each etc. statements
# to handle a custom domain name for AWS CloudFront
# if one was provided as input variable to Terraform.

resource "aws_acm_certificate" "cert" {
  count = var.alternate_domain_name == "" ? 0 : 1

  # CloudFront accepts only ACM certificates from US-EAST-1
  provider = aws.useast1

  domain_name       = "*.${var.alternate_domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  count = var.alternate_domain_name == "" ? 0 : 1

  name    = aws_acm_certificate.cert[0].domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.cert[0].domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.selected[0].zone_id
  records = [aws_acm_certificate.cert[0].domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  count = var.alternate_domain_name == "" ? 0 : 1

  # CloudFront accepts only ACM certificates from US-EAST-1
  provider = aws.useast1

  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn]
}

resource "aws_cloudfront_distribution" "minimal_distribution" {
  origin {
    domain_name = aws_s3_bucket.minimal_frontend_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.minimal_frontend_bucket.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.minimal_cloudfront_identity.cloudfront_access_identity_path
    }
  }

  aliases             = var.alternate_domain_name == "" ? [] : ["www.${var.alternate_domain_name}"]
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.minimal_frontend_bucket.id

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
      acm_certificate_arn = aws_acm_certificate_validation.cert[0].certificate_arn
      ssl_support_method  = "sni-only"
    }
  }
}

resource "aws_route53_record" "www_ipv4" {
  count = var.alternate_domain_name == "" ? 0 : 1

  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = "www.${var.alternate_domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.minimal_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.minimal_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_ipv6" {
  count = var.alternate_domain_name == "" ? 0 : 1

  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = "www.${var.alternate_domain_name}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.minimal_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.minimal_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}
