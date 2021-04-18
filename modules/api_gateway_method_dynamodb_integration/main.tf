resource "aws_api_gateway_method" "this" {
  rest_api_id   = var.rest_api_id
  resource_id   = var.api_gateway_resource_id
  http_method   = var.http_method
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "this" {
  rest_api_id = var.rest_api_id
  resource_id = var.api_gateway_resource_id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "this" {
  rest_api_id             = var.rest_api_id
  resource_id             = var.api_gateway_resource_id
  http_method             = aws_api_gateway_method.this.http_method
  credentials             = var.execution_role_arn
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:dynamodb:action/${var.dynamodb_action}"
  passthrough_behavior    = "NEVER"
  request_templates       = { "application/json" = var.transformation_template }
}

resource "aws_api_gateway_integration_response" "this" {
  rest_api_id = var.rest_api_id
  resource_id = var.api_gateway_resource_id
  http_method = aws_api_gateway_method.this.http_method
  status_code = aws_api_gateway_method_response.this.status_code

  # Recommended by Terraform
  depends_on = [aws_api_gateway_integration.this]
}
