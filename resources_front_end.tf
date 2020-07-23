resource "aws_s3_bucket" "minimal_frontend_bucket" {
  # bucket policy is managed in a separate resource to avoid cyclic dependancies
}

resource "aws_s3_bucket_object" "minimal_index" {
  bucket       = aws_s3_bucket.minimal_frontend_bucket.id
  key          = "index.html"
  source       = "./resources_front_end/index.html"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "minimal_script" {
  bucket = aws_s3_bucket.minimal_frontend_bucket.id
  key    = "index.js"

  content = templatefile(
    "./resources_front_end/index.js",
    {
      api_url = aws_api_gateway_deployment.minimal.invoke_url
    }
  )
}

resource "aws_cloudfront_distribution" "minimal_distribution" {
  origin {
    domain_name = aws_s3_bucket.minimal_frontend_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.minimal_frontend_bucket.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.minimal_cloudfront_identity.cloudfront_access_identity_path
    }
  }

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

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
