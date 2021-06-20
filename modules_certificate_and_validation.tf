module "certificate_and_validation_front_end" {
  count = var.alternate_domain_name == "" ? 0 : 1

  source = "./modules/certificate_and_validation"

  # CloudFront accepts only ACM certificates from US-EAST-1
  providers = { aws = aws.useast1 }

  domain_names = values(local.alternate_domain_names["front_end"])
  zone_id      = data.aws_route53_zone.selected[0].zone_id
}

module "certificate_and_validation_back_end" {
  count = var.alternate_domain_name == "" ? 0 : 1

  source = "./modules/certificate_and_validation"

  domain_names = values(local.alternate_domain_names["back_end"])
  zone_id      = data.aws_route53_zone.selected[0].zone_id
}
