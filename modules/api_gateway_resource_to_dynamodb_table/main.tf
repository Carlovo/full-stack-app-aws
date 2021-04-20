resource "aws_api_gateway_resource" "tables" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = var.table
}

locals {
  table_name = "${var.unique_name_prefix}${aws_api_gateway_resource.tables.path_part}"
}

module "api_gateway_get_dynamodb_scan" {
  source = "../api_gateway_method_dynamodb_integration"

  rest_api_id             = var.rest_api_id
  api_gateway_resource_id = aws_api_gateway_resource.tables.id
  http_method             = "GET"
  execution_role_arn      = var.execution_role_arn
  dynamodb_action         = "Scan"
  transformation_template = jsonencode({ TableName = local.table_name })
}

module "api_gateway_post_dynamodb_put_item" {
  source = "../api_gateway_method_dynamodb_integration"

  rest_api_id             = var.rest_api_id
  api_gateway_resource_id = aws_api_gateway_resource.tables.id
  http_method             = "POST"
  execution_role_arn      = var.execution_role_arn
  dynamodb_action         = "PutItem"
  transformation_template = jsonencode({
    TableName = local.table_name
    Item = {
      id = {
        S = "$context.requestId"
      }
      name = {
        S = "$input.path('$.name')"
      }
      priority = {
        N = "$input.path('$.priority')"
      }
      check = {
        BOOL = "$input.path('$.check')"
      }
      modified = {
        S = "$input.path('$.modified')"
      }
      timestamp = {
        S = "$input.path('$.timestamp')"
      }
    }
  })
}

module "api_gateway_resource_to_dynamodb_item" {
  source = "../api_gateway_resource_to_dynamodb_item"

  rest_api_id        = var.rest_api_id
  parent_id          = aws_api_gateway_resource.tables.id
  execution_role_arn = var.execution_role_arn
  table_name         = local.table_name
}
