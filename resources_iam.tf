resource "aws_cloudfront_origin_access_identity" "s3_access" {}

data "aws_iam_policy_document" "cloudfront_s3_policy" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.front_end.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3_access.iam_arn]
    }
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.front_end.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3_access.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_s3_policy" {
  count = var.insecure ? 0 : 1

  bucket = aws_s3_bucket.front_end.id
  policy = data.aws_iam_policy_document.cloudfront_s3_policy.json
}

module "api_gateway_log_cloudwatch_role" {
  count = var.api_gateway_log_role ? 1 : 0

  source = "./modules/service_role"

  # There can only be one
  # per region
  role_name    = "api-gateway-cloudwatch-${data.aws_region.current.name}"
  service_name = "apigateway"

  permission_statements = [{
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]
    # this seems okay, because it's basically a service linked role
    resources = ["*"]
  }]
}
