resource "aws_api_gateway_rest_api" "crud" {
  name                         = module.front_end.bucket_id
  disable_execute_api_endpoint = var.alternate_domain_name == "" ? false : true

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

module "dynamodb_table_plus_api_gateway_data_access_layer" {
  for_each = var.tables

  source = "./modules/dynamodb_table_plus_api_gateway_data_access_layer"

  unique_name_prefix      = local.unique_name_prefix
  table                   = each.key
  api_gateway_rest_api_id = aws_api_gateway_rest_api.crud.id
  parent_id               = aws_api_gateway_rest_api.crud.root_resource_id
}

resource "aws_api_gateway_deployment" "crud" {
  rest_api_id = aws_api_gateway_rest_api.crud.id

  depends_on = [module.dynamodb_table_plus_api_gateway_data_access_layer]

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment
  # Terraform has diffeculties seeing when redeployment should happen, therefore this dirty hack
  triggers = {
    this_file                 = filesha1("./resources_networking_api_gateway_rest.tf")
    vtl_scan                  = filesha1("./modules/dynamodb_table_plus_api_gateway_data_access_layer/dynamodb_scan.vtl")
    vtl_batchwriteitem        = filesha1("./modules/dynamodb_table_plus_api_gateway_data_access_layer/dynamodb_batchwriteitem.vtl")
    top_module_file           = filesha1("./modules/dynamodb_table_plus_api_gateway_data_access_layer/main.tf")
    resource_integration_file = filesha1("./modules/api_gateway_resource_to_dynamodb/main.tf")
    method_integration_file   = filesha1("./modules/api_gateway_method_integration/main.tf")
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "crud" {
  deployment_id = aws_api_gateway_deployment.crud.id
  rest_api_id   = aws_api_gateway_rest_api.crud.id
  stage_name    = local.crud_stage_name

  depends_on = [aws_cloudwatch_log_group.crud_api]
}

resource "aws_api_gateway_method_settings" "crud" {
  rest_api_id = aws_api_gateway_rest_api.crud.id
  stage_name  = aws_api_gateway_stage.crud.stage_name
  method_path = "*/*"

  settings {
    data_trace_enabled = var.log_apis ? true : false
    logging_level      = var.log_apis ? "INFO" : "OFF"
  }
}

resource "aws_api_gateway_domain_name" "alias" {
  count = var.alternate_domain_name == "" ? 0 : 1

  regional_certificate_arn = module.certificate_and_validation_back_end[0].acm_certificate_arn
  domain_name              = local.alternate_domain_names["back_end"]["crud_api"]
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "alias" {
  count = var.alternate_domain_name == "" ? 0 : 1

  domain_name = aws_api_gateway_domain_name.alias[0].domain_name
  api_id      = aws_api_gateway_rest_api.crud.id
  stage_name  = aws_api_gateway_stage.crud.stage_name
}
