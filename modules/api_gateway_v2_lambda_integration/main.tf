module "this_lambda_function_api" {
  source = "../python_lambda_function"

  function_name               = var.function_name
  source_code                 = var.source_code
  extra_permission_statements = var.extra_permission_statements
  timeout                     = var.timeout
}

resource "aws_apigatewayv2_integration" "this" {
  api_id           = var.api_id
  integration_type = "AWS_PROXY"

  integration_method     = "POST"
  integration_uri        = module.this_lambda_function_api.function_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "this" {
  api_id    = var.api_id
  route_key = "${var.http_method} /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowAPIGatewayV2Invoke"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_execution_arn}/${var.api_stage_name}/${var.http_method}/*"

  depends_on = [module.this_lambda_function_api]
}
