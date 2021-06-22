# API Gateway (V1)

resource "aws_api_gateway_rest_api" "this" {
  name                         = var.unique_name_prefix
  disable_execute_api_endpoint = var.alternate_domain_name == "" ? false : true

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  depends_on = [module.dynamodb_api_gateway_data_tier]

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment
  # Terraform has diffeculties seeing when redeployment should happen, therefore this dirty hack
  triggers = {
    this_file                 = filesha1("${path.module}/resources_networking.tf")
    data_tier_configuration   = filesha1("${path.module}/resources_stateful.tf")
    vtl_scan                  = filesha1("${path.module}/../dynamodb_api_gateway_data_tier/dynamodb_response_scan.vtl")
    vtl_batchwriteitem        = filesha1("${path.module}/../dynamodb_api_gateway_data_tier/dynamodb_request_batchwriteitem.vtl")
    top_module_networking     = filesha1("${path.module}/../dynamodb_api_gateway_data_tier/resources_networking.tf")
    top_module_security       = filesha1("${path.module}/../dynamodb_api_gateway_data_tier/resources_security.tf")
    top_module_stateful       = filesha1("${path.module}/../dynamodb_api_gateway_data_tier/resources_stateful.tf")
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
  count = var.alternate_domain_name == "" ? 0 : 1

  regional_certificate_arn = module.certificate_and_validation[0].acm_certificate_arn
  domain_name              = local.alias_domain_name
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  count = var.alternate_domain_name == "" ? 0 : 1

  domain_name = aws_api_gateway_domain_name.this[0].domain_name
  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
}

# Route53

# API Gateway does not support ipv6 AAAA records
resource "aws_route53_record" "this" {
  count = var.alternate_domain_name == "" ? 0 : 1

  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = aws_api_gateway_domain_name.this[0].domain_name
  type    = "A"

  alias {
    evaluate_target_health = false # not supported for API Gateway, but parameter must be present anyway
    name                   = aws_api_gateway_domain_name.this[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.this[0].regional_zone_id
  }
}
