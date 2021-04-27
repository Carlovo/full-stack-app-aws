resource "aws_api_gateway_resource" "tables" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = var.path_part
}

module "api_gateway_method_dynamodb_integration" {
  for_each = var.integrations

  source = "../api_gateway_method_integration"

  rest_api_id             = var.rest_api_id
  api_gateway_resource_id = aws_api_gateway_resource.tables.id
  http_method             = each.key
  execution_role_arn      = var.execution_role_arn
  integration_uri         = "arn:aws:apigateway:${data.aws_region.current.name}:dynamodb:action/${each.value.dynamodb_action}"
  transformation_template = each.value.transformation_template
}

locals {
  allow_methods = "'OPTIONS,${join(",", keys(var.integrations))}'"
}


module "enable_cors" {
  source = "../api_gateway_method_integration"

  rest_api_id             = var.rest_api_id
  api_gateway_resource_id = aws_api_gateway_resource.tables.id
  http_method             = "OPTIONS"
  execution_role_arn      = null
  integration_uri         = null
  transformation_template = jsonencode({ statusCode = 200 })
  extra_response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = local.allow_methods
    "method.response.header.Access-Control-Max-Age"       = "'900'"
  }
}
