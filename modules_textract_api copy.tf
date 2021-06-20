module "textract_api" {
  count = var.textract_api ? 1 : 0

  source = "./modules/textract_api"

  log_apis = var.log_apis
  alternate_domain_information = var.alternate_domain_name == "" ? {
    domain_name         = ""
    route53_zone_id     = ""
    acm_certificate_arn = ""
    } : {
    domain_name         = local.alternate_domain_names["back_end"]["textract_api"]
    route53_zone_id     = data.aws_route53_zone.selected[0].zone_id
    acm_certificate_arn = module.certificate_and_validation_back_end[0].acm_certificate_arn
  }
}
