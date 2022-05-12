resource "aws_cloudfront_origin_access_identity" "this" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "this" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.this.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }
  }

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }
  }

  statement {
    actions = ["s3:*"]
    effect  = "Deny"

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    not_principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = var.insecure ? 0 : 1

  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}

module "certificate_and_validation" {
  count = var.alternate_domain_name == "" ? 0 : 1

  source = "../certificate_and_validation"

  # CloudFront accepts only ACM certificates from US-EAST-1
  providers = { aws = aws.useast1 }

  domain_names = local.alternate_domain_names
  zone_id      = data.aws_route53_zone.selected[0].zone_id
}
