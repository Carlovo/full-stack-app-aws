resource "aws_api_gateway_resource" "tables" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = var.path_part
}

module "api_gateway_get_dynamodb_scan" {
  for_each = var.integrations

  source = "../api_gateway_method_dynamodb_integration"

  rest_api_id             = var.rest_api_id
  api_gateway_resource_id = aws_api_gateway_resource.tables.id
  http_method             = each.key
  execution_role_arn      = var.execution_role_arn
  dynamodb_action         = each.value.dynamodb_action
  transformation_template = each.value.transformation_template
}
