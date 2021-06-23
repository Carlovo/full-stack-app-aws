module "this_service_role" {
  source = "../service_role"

  role_name    = var.function_name
  service_name = "lambda"

  permission_statements = concat(var.extra_permission_statements,
    [{
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
    }]
  )
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 60
}

data "archive_file" "this" {
  type        = "zip"
  output_path = "${path.module}/${var.function_name}.zip"

  source {
    content  = var.source_code
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name

  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256

  runtime = "python3.8"
  handler = "lambda_function.lambda_handler"
  timeout = var.timeout

  role = module.this_service_role.role_arn
}
