# S3

resource "aws_s3_bucket" "s3_presign" {
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST"]
    allowed_origins = ["*"]
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

  handler = "s3_presign_api.lambda_handler"
  runtime = "python3.8"

  role = aws_iam_role.lambda_s3_presign.arn
}

# API Gateway V2

resource "aws_apigatewayv2_api" "s3_presign" {
  name          = aws_s3_bucket.s3_presign.id
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = ["GET"]
    allow_origins = ["*"]
    max_age       = 900
  }
}

resource "aws_apigatewayv2_integration" "s3_presign" {
  api_id           = aws_apigatewayv2_api.s3_presign.id
  integration_type = "AWS_PROXY"

  integration_method     = "POST"
  integration_uri        = aws_lambda_function.s3_presign.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "s3_presign" {
  api_id    = aws_apigatewayv2_api.s3_presign.id
  route_key = "GET /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.s3_presign.id}"
}

resource "aws_apigatewayv2_stage" "s3_presign" {
  api_id      = aws_apigatewayv2_api.s3_presign.id
  name        = "$default"
  auto_deploy = true
}

# Coupling

resource "aws_lambda_permission" "apigwv2_s3_presign" {
  statement_id  = "AllowAPIGatewayV2Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_presign.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.s3_presign.execution_arn}/${aws_apigatewayv2_stage.s3_presign.name}/GET/*"
}
