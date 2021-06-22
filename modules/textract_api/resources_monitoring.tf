resource "aws_cloudwatch_log_group" "this" {
  count = var.log_apis ? 1 : 0

  name              = "API-Gateway-V2-Execution-Logs_${aws_apigatewayv2_api.this.id}"
  retention_in_days = 60
}
