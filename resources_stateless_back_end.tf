resource "aws_api_gateway_rest_api" "crud" {
  name = aws_s3_bucket.front_end.id
}

module "api_gateway_resource_to_dynamodb_table" {
  source = "./modules/api_gateway_resource_to_dynamodb"

  rest_api_id        = aws_api_gateway_rest_api.crud.id
  parent_id          = aws_api_gateway_rest_api.crud.root_resource_id
  path_part          = tolist(var.tables)[0]
  execution_role_arn = aws_iam_role.api_permissions.arn

  integrations = {
    GET = {
      dynamodb_action         = "Scan"
      request_transformation  = jsonencode({ TableName = aws_dynamodb_table.main[tolist(var.tables)[0]].name })
      response_transformation = <<-EOT
[
#foreach($item in $input.path('$.Items'))
  {
    "id": "$item.id.S",
    "name": "$item.name.S",
    "modified": "$item.modified.S",
    "timestamp": "$item.timestamp.S",
    "priority": $item.priority.N,
    "check": $item.check.BOOL
  }#if($foreach.hasNext),#end
#end
]
EOT
    },
    POST = {
      dynamodb_action = "PutItem"
      request_transformation = jsonencode({
        TableName = aws_dynamodb_table.main[tolist(var.tables)[0]].name
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
  }
}

module "api_gateway_resource_to_dynamodb_item" {
  source = "./modules/api_gateway_resource_to_dynamodb"

  rest_api_id        = aws_api_gateway_rest_api.crud.id
  parent_id          = module.api_gateway_resource_to_dynamodb_table.api_gateway_method_resource_id
  path_part          = "{item}"
  execution_role_arn = aws_iam_role.api_permissions.arn

  integrations = {
    DELETE = {
      dynamodb_action = "DeleteItem"
      request_transformation = jsonencode({
        TableName = aws_dynamodb_table.main[tolist(var.tables)[0]].name
        Key = {
          id = { S = "$input.params('item')" }
        }
      })
    },
    PUT = {
      dynamodb_action = "UpdateItem"
      request_transformation = jsonencode({
        TableName = aws_dynamodb_table.main[tolist(var.tables)[0]].name
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
  }
}

resource "aws_api_gateway_deployment" "crud" {
  rest_api_id = aws_api_gateway_rest_api.crud.id

  depends_on = [
    module.api_gateway_resource_to_dynamodb_table,
    module.api_gateway_resource_to_dynamodb_item
  ]

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment
  # Terraform has diffeculties seeing when redeployment should happen, therefore this dirty hack
  triggers = {
    this_file               = filesha1("./resources_stateless_back_end.tf")
    top_module_file         = filesha1("./modules/api_gateway_resource_to_dynamodb/main.tf")
    integration_module_file = filesha1("./modules/api_gateway_method_integration/main.tf")
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "crud" {
  deployment_id = aws_api_gateway_deployment.crud.id
  rest_api_id   = aws_api_gateway_rest_api.crud.id
  stage_name    = "crud"
}

resource "aws_api_gateway_method_settings" "crud" {
  rest_api_id = aws_api_gateway_rest_api.crud.id
  stage_name  = aws_api_gateway_stage.crud.stage_name
  method_path = "*/*"

  settings {
    data_trace_enabled = var.log_api ? true : null
    logging_level      = var.log_api ? "INFO" : "OFF"
  }
}

resource "aws_api_gateway_domain_name" "alias" {
  count = var.alternate_domain_name == "" ? 0 : 1

  certificate_arn = module.certificate_and_validation[0].acm_certificate_arn
  domain_name     = local.back_end_alternate_domain_name
  security_policy = "TLS_1_2"
}

resource "aws_api_gateway_base_path_mapping" "alias" {
  count = var.alternate_domain_name == "" ? 0 : 1

  domain_name = aws_api_gateway_domain_name.alias[0].domain_name
  api_id      = aws_api_gateway_rest_api.crud.id
  stage_name  = aws_api_gateway_stage.crud.stage_name
}
