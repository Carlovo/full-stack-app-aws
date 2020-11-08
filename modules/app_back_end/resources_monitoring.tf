resource "aws_cloudwatch_log_group" "lambda_function" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = 60
}