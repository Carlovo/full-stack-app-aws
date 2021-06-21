# API Gateway does not support ipv6 AAAA records
resource "aws_route53_record" "crud_api_alias" {
  count = var.alternate_domain_name == "" ? 0 : 1

  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = aws_api_gateway_domain_name.alias[0].domain_name
  type    = "A"

  alias {
    evaluate_target_health = false # not supported for API Gateway, but parameter must be present anyway
    name                   = aws_api_gateway_domain_name.alias[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.alias[0].regional_zone_id
  }
}
