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

data "aws_iam_policy_document" "api_gateway_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api_gateway_logging" {
  count = var.api_gateway_log_role ? 1 : 0

  # There can only be one
  # per region
  name = "api-gateway-cloudwatch-${data.aws_region.current.name}"

  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role_policy.json
}

data "aws_iam_policy_document" "api_gateway_logging" {
  count = var.api_gateway_log_role ? 1 : 0

  statement {
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
  }
}

resource "aws_iam_role_policy" "api_gateway_logging" {
  count = var.api_gateway_log_role ? 1 : 0

  name = aws_iam_role.api_gateway_logging[0].name
  role = aws_iam_role.api_gateway_logging[0].id

  policy = data.aws_iam_policy_document.api_gateway_logging[0].json
}

resource "aws_iam_role" "api_permissions" {
  name = "${aws_s3_bucket.front_end.id}-api-gateway-dynamodb"

  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role_policy.json
}

data "aws_iam_policy_document" "api_permissions" {
  statement {
    actions = [
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem"
    ]
    resources = [for table in var.tables : aws_dynamodb_table.main[table].arn]
  }
}

resource "aws_iam_role_policy" "api_permissions" {
  name = "${aws_s3_bucket.front_end.id}-api-gateway-dynamodb"
  role = aws_iam_role.api_permissions.id

  policy = data.aws_iam_policy_document.api_permissions.json
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_s3_presign" {
  name = "${aws_s3_bucket.s3_presign.id}-lambda-s3-presign"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

data "aws_iam_policy_document" "lambda_s3_presign" {
  statement {
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.s3_presign.arn}/*",
    ]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.lambda_s3_presign.arn}:*"]
  }
}

resource "aws_iam_role_policy" "lambda_s3_presign" {
  name = "${aws_s3_bucket.s3_presign.id}-lambda-s3-presign"
  role = aws_iam_role.lambda_s3_presign.id

  policy = data.aws_iam_policy_document.lambda_s3_presign.json
}
