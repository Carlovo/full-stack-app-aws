# API Gateway (V1)

resource "aws_api_gateway_rest_api" "this" {
  name                         = var.unique_name_prefix
  disable_execute_api_endpoint = var.alternate_domain_information["domain_name"] == "" ? false : true

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

module "dynamodb_table_plus_api_gateway_data_access_layer" {
  for_each = var.tables

  source = "../dynamodb_table_plus_api_gateway_data_access_layer"

  unique_name_prefix      = var.unique_name_prefix
  table                   = each.key
  api_gateway_rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id               = aws_api_gateway_rest_api.this.root_resource_id
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  depends_on = [module.dynamodb_table_plus_api_gateway_data_access_layer]

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment
  # Terraform has diffeculties seeing when redeployment should happen, therefore this dirty hack
  triggers = {
    this_file                 = filesha1("${path.module}/resources_networking.tf")
    vtl_scan                  = filesha1("${path.module}/../dynamodb_table_plus_api_gateway_data_access_layer/dynamodb_scan.vtl")
    vtl_batchwriteitem        = filesha1("${path.module}/../dynamodb_table_plus_api_gateway_data_access_layer/dynamodb_batchwriteitem.vtl")
    top_module_file           = filesha1("${path.module}/../dynamodb_table_plus_api_gateway_data_access_layer/main.tf")
    resource_integration_file = filesha1("${path.module}/../api_gateway_resource_to_dynamodb/main.tf")
    method_integration_file   = filesha1("${path.module}/../api_gateway_method_integration/main.tf")
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = local.crud_stage_name

  depends_on = [aws_cloudwatch_log_group.this]
}

resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    data_trace_enabled = var.log_apis ? true : false
    logging_level      = var.log_apis ? "INFO" : "OFF"
  }
}

resource "aws_api_gateway_domain_name" "this" {
  count = var.alternate_domain_information["domain_name"] == "" ? 0 : 1

  regional_certificate_arn = var.alternate_domain_information["acm_certificate_arn"]
  domain_name              = var.alternate_domain_information["domain_name"]
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  count = var.alternate_domain_information["domain_name"] == "" ? 0 : 1

  domain_name = aws_api_gateway_domain_name.this[0].domain_name
  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
}

# Route53

# API Gateway does not support ipv6 AAAA records
resource "aws_route53_record" "this" {
  count = var.alternate_domain_information["domain_name"] == "" ? 0 : 1

  zone_id = var.alternate_domain_information["route53_zone_id"]
  name    = aws_api_gateway_domain_name.this[0].domain_name
  type    = "A"

  alias {
    evaluate_target_health = false # not supported for API Gateway, but parameter must be present anyway
    name                   = aws_api_gateway_domain_name.this[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.this[0].regional_zone_id
  }
}
