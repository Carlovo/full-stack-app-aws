module "s3_put_role" {
  source = "../service_role"

  role_name    = "apigateway-PutObject-${aws_s3_bucket.image_uploads.bucket}"
  service_name = "apigateway"

  permission_statements = [{
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.image_uploads.arn}/*"]
  }]
}

resource "aws_api_gateway_rest_api" "this" {
  name = "PutObject-${aws_s3_bucket.image_uploads.bucket}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_method" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_rest_api.this.root_resource_id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_rest_api.this.root_resource_id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "200"
}

data "aws_region" "current" {}

resource "aws_api_gateway_integration" "this" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_rest_api.this.root_resource_id
  http_method             = aws_api_gateway_method.this.http_method
  credentials             = module.s3_put_role.role_arn
  integration_http_method = "PUT"
  type                    = "AWS"
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:s3:path/${aws_s3_bucket.image_uploads.bucket}/test.html"
}

resource "aws_api_gateway_integration_response" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_rest_api.this.root_resource_id
  http_method = aws_api_gateway_method.this.http_method
  status_code = aws_api_gateway_method_response.this.status_code

  # Recommended by Terraform
  depends_on = [aws_api_gateway_integration.this]
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  depends_on = [aws_api_gateway_integration_response.this]

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment
  # Terraform has diffeculties seeing when redeployment should happen, therefore this dirty hack
  triggers = { this_file = filesha1("${path.module}/resources_networking_v2.tf") }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "test"
}
