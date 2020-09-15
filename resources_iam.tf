# front end

resource "aws_cloudfront_origin_access_identity" "minimal_cloudfront_identity" {}

data "aws_iam_policy_document" "cloudfront_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.minimal_frontend_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.minimal_cloudfront_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_s3_policy" {
  count = var.insecure ? 0 : 1

  bucket = aws_s3_bucket.minimal_frontend_bucket.id
  policy = data.aws_iam_policy_document.cloudfront_s3_policy.json
}

# back end

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
  name = "lambda-dynamodb-role"

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
    resources = [aws_dynamodb_table.minimal_backend_table.arn]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.backend_function.arn}:*"]
  }
}

resource "aws_iam_role_policy" "function_permissions" {
  name = "lambda-dynamodb-policy"
  role = aws_iam_role.function_assume_role.id

  policy = data.aws_iam_policy_document.function_permissions.json
}
