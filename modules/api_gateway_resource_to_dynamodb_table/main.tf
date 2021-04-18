resource "aws_api_gateway_resource" "tables" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = var.table
}

module "api_gateway_get_dynamodb_scan" {
  source = "../api_gateway_method_dynamodb_integration"

  rest_api_id             = var.rest_api_id
  api_gateway_resource_id = aws_api_gateway_resource.tables.id
  http_method             = "GET"
  execution_role_arn      = var.execution_role_arn
  dynamodb_action         = "Scan"
  transformation_template = jsonencode({ TableName = "${var.unique_name_prefix}${aws_api_gateway_resource.tables.path_part}" })
}
