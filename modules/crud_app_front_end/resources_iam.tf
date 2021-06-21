resource "aws_cloudfront_origin_access_identity" "s3_access" {}

data "aws_iam_policy_document" "cloudfront_s3_policy" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.this.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3_access.iam_arn]
    }
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3_access.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_s3_policy" {
  count = var.insecure ? 0 : 1

  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.cloudfront_s3_policy.json
}

module "certificate_and_validation" {
  count = var.alternate_domain_name == "" ? 0 : 1

  source = "../certificate_and_validation"

  # CloudFront accepts only ACM certificates from US-EAST-1
  providers = { aws = aws.useast1 }

  domain_names = local.alternate_domain_names
  zone_id      = var.route53_zone_id
}
