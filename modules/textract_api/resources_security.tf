module "certificate_and_validation" {
  count = var.alternate_domain_name == "" ? 0 : 1

  source = "../certificate_and_validation"

  domain_names = [local.alias_domain_name]
  zone_id      = data.aws_route53_zone.selected[0].zone_id
}
