module "api_gateway_log_cloudwatch_role" {
  count = var.api_gateway_log_role ? 1 : 0

  source = "./modules/service_role"

  # There can only be one
  # per region
  role_name    = "api-gateway-cloudwatch-${data.aws_region.current.name}"
  service_name = "apigateway"

  permission_statements = [{
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]
    # this seems okay, because it's basically a service linked role
    resources = ["*"]
  }]
}
