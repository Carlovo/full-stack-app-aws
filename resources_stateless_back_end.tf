resource "aws_api_gateway_rest_api" "crud" {
  name = aws_s3_bucket.front_end.id
}

locals {
  api_path_table = "table_name"
}

resource "aws_api_gateway_resource" "tables" {
  rest_api_id = aws_api_gateway_rest_api.crud.id
  parent_id   = aws_api_gateway_rest_api.crud.root_resource_id
  path_part   = tolist(var.tables)[0]
}

resource "aws_api_gateway_method" "scan_table" {
  rest_api_id   = aws_api_gateway_rest_api.crud.id
  resource_id   = aws_api_gateway_resource.tables.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "scan_table" {
  rest_api_id = aws_api_gateway_rest_api.crud.id
  resource_id = aws_api_gateway_resource.tables.id
  http_method = aws_api_gateway_method.scan_table.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "scan_table" {
  rest_api_id             = aws_api_gateway_rest_api.crud.id
  resource_id             = aws_api_gateway_resource.tables.id
  http_method             = aws_api_gateway_method.scan_table.http_method
  credentials             = aws_iam_role.api_permissions.arn
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:dynamodb:action/Scan"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = jsonencode(
      {
        TableName = "${local.unique_name_prefix}${aws_api_gateway_resource.tables.path_part}"
      }
    )
  }
}

resource "aws_api_gateway_integration_response" "scan_table" {
  rest_api_id = aws_api_gateway_rest_api.crud.id
  resource_id = aws_api_gateway_resource.tables.id
  http_method = aws_api_gateway_method.scan_table.http_method
  status_code = aws_api_gateway_method_response.scan_table.status_code

  # Recommended by Terraform
  depends_on = [aws_api_gateway_integration.scan_table]
}

resource "aws_api_gateway_deployment" "crud" {
  rest_api_id = aws_api_gateway_rest_api.crud.id

  depends_on = [
    aws_api_gateway_resource.tables,
    aws_api_gateway_method.scan_table,
    aws_api_gateway_method_response.scan_table,
    aws_api_gateway_integration.scan_table,
    aws_api_gateway_integration_response.scan_table
  ]

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment
  # Terraform has diffeculties seeing when redeployment should happen, therefore this dirty hack
  triggers = {
    redeployment = filesha1("./resources_stateless_back_end.tf")
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
