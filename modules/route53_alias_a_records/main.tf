resource "aws_route53_record" "ipv4" {
  zone_id = var.hosted_zone_id
  name    = var.dns_record_name
  type    = "A"

  alias {
    name                   = var.alias_domain_name
    zone_id                = var.alias_hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ipv6" {
  zone_id = var.hosted_zone_id
  name    = var.dns_record_name
  type    = "AAAA"

  alias {
    name                   = var.alias_domain_name
    zone_id                = var.alias_hosted_zone_id
    evaluate_target_health = true
  }
}
