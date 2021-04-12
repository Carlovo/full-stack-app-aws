resource "aws_api_gateway_rest_api" "crud" {
  name = aws_s3_bucket.front_end.id
}

module "api_gateway_resource_to_dynamodb_table" {
  source = "./modules/api_gateway_resource_to_dynamodb_table"

  rest_api_id        = aws_api_gateway_rest_api.crud.id
  parent_id          = aws_api_gateway_rest_api.crud.root_resource_id
  execution_role_arn = aws_iam_role.api_permissions.arn
  unique_name_prefix = local.unique_name_prefix
  table              = tolist(var.tables)[0]
}

resource "aws_api_gateway_deployment" "crud" {
  rest_api_id = aws_api_gateway_rest_api.crud.id

  depends_on = [module.api_gateway_resource_to_dynamodb_table]

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment
  # Terraform has diffeculties seeing when redeployment should happen, therefore this dirty hack
  triggers = {
    this_file   = filesha1("./resources_stateless_back_end.tf")
    module_file = filesha1("./modules/api_gateway_resource_to_dynamodb_table/main.tf")
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
