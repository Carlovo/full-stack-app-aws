# API Gateway V2

resource "aws_apigatewayv2_api" "this" {
  name                         = aws_s3_bucket.image_uploads.id
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

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  dynamic "access_log_settings" {
    for_each = var.log_apis ? [1] : []

    content {
      destination_arn = aws_cloudwatch_log_group.this[0].arn
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
  source = "../api_gateway_v2_lambda_integration"

  api_id            = aws_apigatewayv2_api.this.id
  http_method       = "GET"
  api_execution_arn = aws_apigatewayv2_api.this.execution_arn
  api_stage_name    = aws_apigatewayv2_stage.this.name

  function_name = "${aws_s3_bucket.image_uploads.id}-s3-presign"

  source_code = templatefile("${path.module}/s3_presign_api.py", {
    bucket_name = aws_s3_bucket.image_uploads.id
  })

  extra_permission_statements = [{
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.image_uploads.arn}/*"]
  }]
}

module "api_gateway_v2_lambda_integration" {
  source = "../api_gateway_v2_lambda_integration"

  api_id            = aws_apigatewayv2_api.this.id
  http_method       = "POST"
  api_execution_arn = aws_apigatewayv2_api.this.execution_arn
  api_stage_name    = aws_apigatewayv2_stage.this.name

  function_name = "${aws_s3_bucket.image_uploads.id}-textract"
  timeout       = 90

  source_code = templatefile("${path.module}/textract_api.py", {
    bucket_name = aws_s3_bucket.image_uploads.id
  })

  extra_permission_statements = [
    {
      actions   = ["textract:DetectDocumentText"]
      resources = ["*"]
    },
    {
      actions   = ["s3:GetObject"]
      resources = ["${aws_s3_bucket.image_uploads.arn}/*"]
    }
  ]
}

resource "aws_apigatewayv2_domain_name" "this" {
  count = var.alternate_domain_name == "" ? 0 : 1

  domain_name = local.alias_domain_name

  domain_name_configuration {
    certificate_arn = module.certificate_and_validation[0].acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "this" {
  count = var.alternate_domain_name == "" ? 0 : 1

  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.this[0].id
  stage       = aws_apigatewayv2_stage.this.id
}

# Route53

# API Gateway V2 does not support ipv6 AAAA records
resource "aws_route53_record" "this" {
  count = var.alternate_domain_name == "" ? 0 : 1

  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = aws_apigatewayv2_domain_name.this[0].domain_name
  type    = "A"

  alias {
    evaluate_target_health = false # not supported for API Gateway, but parameter must be present anyway
    name                   = aws_apigatewayv2_domain_name.this[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.this[0].domain_name_configuration[0].hosted_zone_id
  }
}
