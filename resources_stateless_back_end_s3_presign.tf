# S3

resource "aws_s3_bucket" "s3_presign" {
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST"]
    allowed_origins = ["*"]
  }

  lifecycle_rule {
    id      = "delete-all-1-day"
    enabled = true

    abort_incomplete_multipart_upload_days = 1

    noncurrent_version_expiration {
      days = 1
    }

    expiration {
      days = 1
    }
  }
}

# API Gateway V2

resource "aws_apigatewayv2_api" "s3_presign" {
  name                         = aws_s3_bucket.s3_presign.id
  protocol_type                = "HTTP"
  disable_execute_api_endpoint = var.alternate_domain_name == "" ? false : true

  cors_configuration {
    allow_methods = [
      "GET",
      "POST"
    ]
    allow_origins = ["*"]
    max_age       = 900
  }
}

resource "aws_apigatewayv2_stage" "s3_presign" {
  api_id      = aws_apigatewayv2_api.s3_presign.id
  name        = "$default"
  auto_deploy = true

  dynamic "access_log_settings" {
    for_each = var.log_api ? [1] : []

    content {
      destination_arn = aws_cloudwatch_log_group.textract_api[0].arn
      format = jsonencode(
        {
          httpMethod     = "$context.httpMethod"
          ip             = "$context.identity.sourceIp"
          protocol       = "$context.protocol"
          requestId      = "$context.requestId"
          requestTime    = "$context.requestTime"
          responseLength = "$context.responseLength"
          routeKey       = "$context.routeKey"
          status         = "$context.status"
        }
      )
    }
  }
}

module "api_gateway_v2_lambda_integration_s3_presign" {
  source = "./modules/api_gateway_v2_lambda_integration"

  api_id            = aws_apigatewayv2_api.s3_presign.id
  http_method       = "GET"
  api_execution_arn = aws_apigatewayv2_api.s3_presign.execution_arn
  api_stage_name    = aws_apigatewayv2_stage.s3_presign.name

  function_name = "${aws_s3_bucket.s3_presign.id}-s3-presign"

  source_code = templatefile("./terraform_templates/back_end/s3_presign_api.py", {
    bucket_name = aws_s3_bucket.s3_presign.id
  })

  extra_permission_statements = [{
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.s3_presign.arn}/*"]
  }]
}

module "api_gateway_v2_lambda_integration_textract" {
  source = "./modules/api_gateway_v2_lambda_integration"

  api_id            = aws_apigatewayv2_api.s3_presign.id
  http_method       = "POST"
  api_execution_arn = aws_apigatewayv2_api.s3_presign.execution_arn
  api_stage_name    = aws_apigatewayv2_stage.s3_presign.name

  function_name = "${aws_s3_bucket.s3_presign.id}-textract"
  timeout       = 90

  source_code = templatefile("./terraform_templates/back_end/textract_api.py", {
    bucket_name = aws_s3_bucket.s3_presign.id
  })

  extra_permission_statements = [
    {
      actions   = ["textract:DetectDocumentText"]
      resources = ["*"]
    },
    {
      actions   = ["s3:GetObject"]
      resources = ["${aws_s3_bucket.s3_presign.arn}/*"]
    }
  ]
}

resource "aws_apigatewayv2_domain_name" "alias" {
  count = var.alternate_domain_name == "" ? 0 : 1

  domain_name = local.alternate_domain_names["back_end"]["upload_api"]

  domain_name_configuration {
    certificate_arn = module.certificate_and_validation_back_end[0].acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "alias" {
  count = var.alternate_domain_name == "" ? 0 : 1

  api_id      = aws_apigatewayv2_api.s3_presign.id
  domain_name = aws_apigatewayv2_domain_name.alias[0].id
  stage       = aws_apigatewayv2_stage.s3_presign.id
}