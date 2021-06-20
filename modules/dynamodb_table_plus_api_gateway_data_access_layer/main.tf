resource "aws_dynamodb_table" "this" {
  name         = "${var.unique_name_prefix}${var.table}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

module "api_gateway_crud_dynamodb_items_role" {
  source = "../service_role"

  role_name    = "crud-${aws_dynamodb_table.this.name}"
  service_name = "apigateway"

  permission_statements = [{
    actions = [
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem"
    ]
    resources = [aws_dynamodb_table.this.arn]
  }]
}

module "api_gateway_resource_to_dynamodb_table" {
  source = "../api_gateway_resource_to_dynamodb"

  rest_api_id        = var.api_gateway_rest_api_id
  parent_id          = var.parent_id
  path_part          = var.table
  execution_role_arn = module.api_gateway_crud_dynamodb_items_role.role_arn

  integrations = {
    GET = {
      dynamodb_action         = "Scan"
      request_transformation  = jsonencode({ TableName = aws_dynamodb_table.this.name })
      response_transformation = file("${path.module}/dynamodb_scan.vtl")
    },
    POST = {
      dynamodb_action = "BatchWriteItem"
      request_transformation = templatefile(
        "${path.module}/dynamodb_batchwriteitem.vtl",
        {
          dynamodb_table_name = aws_dynamodb_table.this.name
        }
      )
    }
  }
}

module "api_gateway_resource_to_dynamodb_item" {
  source = "../api_gateway_resource_to_dynamodb"

  rest_api_id        = var.api_gateway_rest_api_id
  parent_id          = module.api_gateway_resource_to_dynamodb_table.api_gateway_method_resource_id
  path_part          = "{item}"
  execution_role_arn = module.api_gateway_crud_dynamodb_items_role.role_arn

  integrations = {
    DELETE = {
      dynamodb_action = "DeleteItem"
      request_transformation = jsonencode({
        TableName = aws_dynamodb_table.this.name
        Key = {
          id = { S = "$input.params('item')" }
        }
      })
    },
    PATCH = {
      dynamodb_action = "UpdateItem"
      request_transformation = jsonencode({
        TableName = aws_dynamodb_table.this.name
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
            N = "$context.requestTimeEpoch"
          }
        }
      })
    }
  }
}
