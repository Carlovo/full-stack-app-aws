# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account
# As there is no API method for deleting account settings or resetting it to defaults,
# destroying this resource will not do anything.
resource "aws_api_gateway_account" "this_region" {
  count = var.api_gateway_log_role ? 1 : 0

  cloudwatch_role_arn = aws_iam_role.api_gateway_logging[0].arn
}

resource "aws_cloudwatch_log_group" "lambda_s3_presign" {
  name              = "/aws/lambda/${aws_lambda_function.s3_presign.function_name}"
  retention_in_days = 60
}

resource "aws_cloudwatch_log_group" "lambda_textract" {
  name              = "/aws/lambda/${aws_lambda_function.textract.function_name}"
  retention_in_days = 60
}
