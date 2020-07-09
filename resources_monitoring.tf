resource "aws_cloudwatch_log_group" "backend_function" {
  name              = "/aws/lambda/${aws_lambda_function.minimal_backend_function.function_name}"
  retention_in_days = 60
}
