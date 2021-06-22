module "api_gateway_log_cloudwatch_role" {
  count = var.api_gateway_log_role ? 1 : 0

  source = "../service_role"

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

module "certificate_and_validation" {
  count = var.alternate_domain_name == "" ? 0 : 1

  source = "../certificate_and_validation"

  domain_names = [local.alias_domain_name]
  zone_id      = data.aws_route53_zone.selected[0].zone_id
}
