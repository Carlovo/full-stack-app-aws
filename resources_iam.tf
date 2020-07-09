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
    sid = "LambdaDynamodb"
    actions = [
      "dynamodb:Scan",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem"
    ]
    resources = [aws_dynamodb_table.minimal_backend_table.arn]
  }
}

resource "aws_iam_role_policy" "function_permissions" {
  name = "lambda-dynamodb-policy"
  role = aws_iam_role.function_assume_role.id

  policy = data.aws_iam_policy_document.function_permissions.json
}
