# Lambda function

data "archive_file" "crud_function_package" {
  type        = "zip"
  source_file = "./database_connector.py"
  output_path = "./database_connector.zip"
}

resource "aws_lambda_function" "crud" {
  function_name = aws_s3_bucket.front_end.id

  filename         = data.archive_file.crud_function_package.output_path
  source_code_hash = data.archive_file.crud_function_package.output_base64sha256

  handler = "database_connector.lambda_handler"
  runtime = "python3.8"

  role = aws_iam_role.function_assume_role.arn

  environment {
    variables = {
      table_name_prefix = local.unique_name_prefix
    }
  }
}

# API Gateway

resource "aws_api_gateway_rest_api" "crud" {
  name = aws_s3_bucket.front_end.id
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.crud.id
  resource_id   = aws_api_gateway_rest_api.crud.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.crud.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.crud.invoke_arn
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.crud.id
  parent_id   = aws_api_gateway_rest_api.crud.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.crud.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.crud.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.crud.invoke_arn
}

resource "aws_api_gateway_deployment" "crud" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.crud.id
  stage_name  = "crud"
}

resource "aws_lambda_permission" "api_invoke_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.crud.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.crud.execution_arn}/*/*"
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
  stage_name  = aws_api_gateway_deployment.crud.stage_name
}
