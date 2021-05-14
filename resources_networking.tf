module "certificate_and_validation" {
  count = var.alternate_domain_name == "" ? 0 : 1

  source = "./modules/certificate_and_validation"

  # CloudFront accepts only ACM certificates from US-EAST-1
  providers = {
    aws = aws.useast1
  }

  domain_names = concat(local.front_end_alternate_domain_names, [local.back_end_alternate_domain_name])
  zone_id      = data.aws_route53_zone.selected[0].zone_id
}

resource "aws_cloudfront_distribution" "front_end" {
  origin {
    domain_name = aws_s3_bucket.front_end.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.front_end.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_access.cloudfront_access_identity_path
    }
  }

  aliases             = local.front_end_alternate_domain_names
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = aws_s3_bucket_object.index.key

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.front_end.id

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

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/${aws_s3_bucket_object.page_404.key}"
  }

  # conditional nested blocks are not supported by Terraform, therefore this hack
  dynamic "viewer_certificate" {
    for_each = var.alternate_domain_name == "" ? [1] : []
    content {
      cloudfront_default_certificate = true
      minimum_protocol_version       = "TLSv1.2_2019"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.alternate_domain_name == "" ? [] : [1]
    content {
      acm_certificate_arn      = module.certificate_and_validation[0].acm_certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2019"
    }
  }
}

module "alias_a_records" {
  for_each = toset(local.front_end_alternate_domain_names)

  source = "./modules/route53_alias_a_records"

  dns_record_name = each.key

  hosted_zone_id       = data.aws_route53_zone.selected[0].zone_id
  alias_domain_name    = aws_cloudfront_distribution.front_end.domain_name
  alias_hosted_zone_id = aws_cloudfront_distribution.front_end.hosted_zone_id
}

# API Gateway does not support ipv6 AAAA records
resource "aws_route53_record" "api_alias" {
  count = var.alternate_domain_name == "" ? 0 : 1

  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = aws_api_gateway_domain_name.alias[0].domain_name
  type    = "A"

  alias {
    evaluate_target_health = false # not support for API Gateway, but parameter must be present anyway
    name                   = aws_api_gateway_domain_name.alias[0].cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.alias[0].cloudfront_zone_id
  }
}
