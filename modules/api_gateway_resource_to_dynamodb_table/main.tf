resource "aws_api_gateway_resource" "tables" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = var.table
}

resource "aws_api_gateway_method" "scan_table" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.tables.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "scan_table" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.tables.id
  http_method = aws_api_gateway_method.scan_table.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "scan_table" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.tables.id
  http_method             = aws_api_gateway_method.scan_table.http_method
  credentials             = var.execution_role_arn
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:dynamodb:action/Scan"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = jsonencode(
      {
        TableName = "${var.unique_name_prefix}${aws_api_gateway_resource.tables.path_part}"
      }
    )
  }
}

resource "aws_api_gateway_integration_response" "scan_table" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.tables.id
  http_method = aws_api_gateway_method.scan_table.http_method
  status_code = aws_api_gateway_method_response.scan_table.status_code

  # Recommended by Terraform
  depends_on = [aws_api_gateway_integration.scan_table]
}
