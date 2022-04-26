data "aws_cloudfront_cache_policy" "managed_caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_function" "redirect_missing_file_extension_to_html" {
  count = var.redirect_missing_file_extension_to_html ? 1 : 0

  name    = "${var.app_id}-redirect"
  runtime = "cloudfront-js-1.0"
  code    = file("${path.module}/content/redirect_missing_file_extension_to_html.js")
}

resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.this.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  aliases             = local.alternate_domain_names
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
    target_origin_id       = aws_s3_bucket.this.id
    viewer_protocol_policy = "redirect-to-https"

    dynamic "function_association" {
      for_each = var.redirect_missing_file_extension_to_html ? [1] : []
      content {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.redirect_missing_file_extension_to_html[0].arn
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/${aws_s3_object.page_404.key}"
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
      acm_certificate_arn      = module.certificate_and_validation[0].acm_certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2019"
    }
  }
}

module "alias_a_records" {
  for_each = toset(local.alternate_domain_names)

  source = "../route53_alias_a_records"

  dns_record_name = each.key

  hosted_zone_id       = data.aws_route53_zone.selected[0].zone_id
  alias_domain_name    = aws_cloudfront_distribution.this.domain_name
  alias_hosted_zone_id = aws_cloudfront_distribution.this.hosted_zone_id
}
