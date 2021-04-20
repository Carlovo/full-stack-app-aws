resource "aws_api_gateway_resource" "items" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = "{item}"
}

module "api_gateway_delete_dynamodb_delete_item" {
  source = "../api_gateway_method_dynamodb_integration"

  rest_api_id             = var.rest_api_id
  api_gateway_resource_id = aws_api_gateway_resource.items.id
  http_method             = "DELETE"
  execution_role_arn      = var.execution_role_arn
  dynamodb_action         = "DeleteItem"
  transformation_template = jsonencode({
    TableName = var.table_name
    Key = {
      id = { S = "$input.params('item')" }
    }
  })
}

module "api_gateway_put_dynamodb_put_item" {
  source = "../api_gateway_method_dynamodb_integration"

  rest_api_id             = var.rest_api_id
  api_gateway_resource_id = aws_api_gateway_resource.items.id
  http_method             = "PUT"
  execution_role_arn      = var.execution_role_arn
  dynamodb_action         = "UpdateItem"
  transformation_template = jsonencode({
    TableName        = var.table_name
    Key = {
      id = { S = "$input.params('item')" }
    }
    UpdateExpression = "SET #n = :new_name, #p = :new_priority, #c = :new_check, #m = :new_modified",
    ExpressionAttributeNames = {
      "#n" = "name"
      "#p" = "priority"
      "#c" = "check"
      "#m" = "modified"
    }
    ExpressionAttributeValues = {
      ":new_name" = {
        S = "$input.path('$.name')"
      }
      ":new_priority" = {
        N = "$input.path('$.priority')"
      }
      ":new_check" = {
        BOOL = "$input.path('$.check')"
      }
      ":new_modified" = {
        S = "$input.path('$.modified')"
      }
    }
  })
}
