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
  name = "${var.resource_name}-lambda-dynamodb"

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
    resources = [aws_dynamodb_table.main.arn]
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
  name = "${var.resource_name}-lambda-dynamodb"
  role = aws_iam_role.function_assume_role.id

  policy = data.aws_iam_policy_document.function_permissions.json
}
