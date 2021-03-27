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

data "aws_iam_policy_document" "function_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "function_assume_role" {
  name = "${aws_s3_bucket.front_end.id}-lambda-dynamodb"

  assume_role_policy = data.aws_iam_policy_document.function_assume_role_policy.json
}

data "aws_iam_policy_document" "function_permissions" {
  statement {
    actions = [
      "dynamodb:Scan",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem"
    ]
    resources = [for table in var.tables : aws_dynamodb_table.main[table].arn]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.lambda_function.arn}:*"]
  }
}

resource "aws_iam_role_policy" "function_permissions" {
  name = "${aws_s3_bucket.front_end.id}-lambda-dynamodb"
  role = aws_iam_role.function_assume_role.id

  policy = data.aws_iam_policy_document.function_permissions.json
}
