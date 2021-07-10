resource "aws_api_gateway_resource" "this" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = var.path_part
}

module "api_gateway_method_dynamodb_integration" {
  for_each = var.integrations

  source = "../api_gateway_method_integration"

  rest_api_id             = var.rest_api_id
  api_gateway_resource_id = aws_api_gateway_resource.this.id
  http_method             = each.key
  execution_role_arn      = var.execution_role_arn
  integration_uri         = "arn:aws:apigateway:${data.aws_region.current.name}:dynamodb:action/${each.value.dynamodb_action}"
  request_transformation  = each.value.request_transformation
  response_transformation = lookup(each.value, "response_transformation", null)
  enforce_api_key         = var.enforce_api_key
}

locals {
  allow_methods = "'OPTIONS,${join(",", keys(var.integrations))}'"
}


module "enable_cors" {
  source = "../api_gateway_method_integration"

  rest_api_id             = var.rest_api_id
  api_gateway_resource_id = aws_api_gateway_resource.this.id
  http_method             = "OPTIONS"
  execution_role_arn      = null
  integration_uri         = null
  request_transformation  = jsonencode({ statusCode = 200 })
  extra_response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = local.allow_methods
    "method.response.header.Access-Control-Max-Age"       = "'900'"
  }
}
