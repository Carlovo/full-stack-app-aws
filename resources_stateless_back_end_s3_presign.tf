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

# Lambda

data "archive_file" "s3_presign_api" {
  type        = "zip"
  output_path = "./terraform_templates/back_end/s3_presign_api.zip"

  source {
    content = templatefile("./terraform_templates/back_end/s3_presign_api.py", {
      bucket_name = aws_s3_bucket.s3_presign.id
    })
    filename = "s3_presign_api.py"
  }
}

resource "aws_lambda_function" "s3_presign" {
  function_name = "${aws_s3_bucket.s3_presign.id}-s3-presign"

  filename         = data.archive_file.s3_presign_api.output_path
  source_code_hash = data.archive_file.s3_presign_api.output_base64sha256

  timeout = 90
  handler = "s3_presign_api.lambda_handler"
  runtime = "python3.8"

  role = aws_iam_role.lambda_s3_presign.arn
}

data "archive_file" "textract_api" {
  type        = "zip"
  output_path = "./terraform_templates/back_end/textract_api.zip"

  source {
    content = templatefile("./terraform_templates/back_end/textract_api.py", {
      bucket_name = aws_s3_bucket.s3_presign.id
    })
    filename = "textract_api.py"
  }
}

resource "aws_lambda_function" "textract" {
  function_name = "${aws_s3_bucket.s3_presign.id}-textract"

  filename         = data.archive_file.textract_api.output_path
  source_code_hash = data.archive_file.textract_api.output_base64sha256

  handler = "textract_api.lambda_handler"
  runtime = "python3.8"

  role = aws_iam_role.lambda_textract.arn
}

# API Gateway V2

resource "aws_apigatewayv2_api" "s3_presign" {
  name          = aws_s3_bucket.s3_presign.id
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = [
      "GET",
      "POST"
    ]
    allow_origins = ["*"]
    max_age       = 900
  }
}

resource "aws_apigatewayv2_integration" "s3_presign" {
  api_id           = aws_apigatewayv2_api.s3_presign.id
  integration_type = "AWS_PROXY"

  integration_method     = "POST"
  integration_uri        = aws_lambda_function.s3_presign.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "s3_presign" {
  api_id    = aws_apigatewayv2_api.s3_presign.id
  route_key = "GET /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.s3_presign.id}"
}

resource "aws_apigatewayv2_integration" "textract" {
  api_id           = aws_apigatewayv2_api.s3_presign.id
  integration_type = "AWS_PROXY"

  integration_method     = "POST"
  integration_uri        = aws_lambda_function.textract.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "textract" {
  api_id    = aws_apigatewayv2_api.s3_presign.id
  route_key = "POST /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.textract.id}"
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

# Coupling

resource "aws_lambda_permission" "apigwv2_s3_presign" {
  statement_id  = "AllowAPIGatewayV2Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_presign.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.s3_presign.execution_arn}/${aws_apigatewayv2_stage.s3_presign.name}/GET/*"
}

resource "aws_lambda_permission" "apigwv2_textract" {
  statement_id  = "AllowAPIGatewayV2Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.textract.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.s3_presign.execution_arn}/${aws_apigatewayv2_stage.s3_presign.name}/POST/*"
}
