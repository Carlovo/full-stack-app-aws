resource "aws_api_gateway_method" "this" {
  rest_api_id      = var.rest_api_id
  resource_id      = var.api_gateway_resource_id
  http_method      = var.http_method
  api_key_required = var.enforce_api_key
  authorization    = "NONE"
}

locals {
  response_parameters = merge(
    var.extra_response_parameters,
    { "method.response.header.Access-Control-Allow-Origin" = "'*'" }
  )
}

resource "aws_api_gateway_method_response" "this" {
  rest_api_id         = var.rest_api_id
  resource_id         = var.api_gateway_resource_id
  http_method         = aws_api_gateway_method.this.http_method
  status_code         = "200"
  response_parameters = { for parameter in keys(local.response_parameters) : parameter => false }
}

resource "aws_api_gateway_integration" "this" {
  rest_api_id             = var.rest_api_id
  resource_id             = var.api_gateway_resource_id
  http_method             = aws_api_gateway_method.this.http_method
  credentials             = var.execution_role_arn
  integration_http_method = var.integration_uri == null ? null : "POST"
  type                    = var.integration_uri == null ? "MOCK" : "AWS"
  uri                     = var.integration_uri
  passthrough_behavior    = "NEVER"
  request_templates       = { "application/json" = var.request_transformation }
}

resource "aws_api_gateway_integration_response" "this" {
  rest_api_id         = var.rest_api_id
  resource_id         = var.api_gateway_resource_id
  http_method         = aws_api_gateway_method.this.http_method
  status_code         = aws_api_gateway_method_response.this.status_code
  response_parameters = local.response_parameters
  response_templates  = var.response_transformation == null ? null : { "application/json" = var.response_transformation }

  # Recommended by Terraform
  depends_on = [aws_api_gateway_integration.this]
}
