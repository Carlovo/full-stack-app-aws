module "certificate_and_validation_back_end" {
  count = var.alternate_domain_name == "" ? 0 : 1

  source = "./modules/certificate_and_validation"

  domain_names = values(local.alternate_domain_names["back_end"])
  zone_id      = data.aws_route53_zone.selected[0].zone_id
}

module "crud_api" {
  source = "./modules/crud_api"

  tables               = var.tables
  log_apis             = var.log_apis
  api_gateway_log_role = var.api_gateway_log_role
  unique_name_prefix   = local.unique_name_prefix

  alternate_domain_information = var.alternate_domain_name == "" ? {
    domain_name         = ""
    route53_zone_id     = ""
    acm_certificate_arn = ""
    } : {
    domain_name         = local.alternate_domain_names["back_end"]["crud_api"]
    route53_zone_id     = data.aws_route53_zone.selected[0].zone_id
    acm_certificate_arn = module.certificate_and_validation_back_end[0].acm_certificate_arn
  }
}

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

module "front_end" {
  source = "./modules/crud_app_front_end"

  tables                           = var.tables
  insecure                         = var.insecure
  alternate_domain_name            = var.alternate_domain_name
  route53_zone_id                  = var.alternate_domain_name == "" ? "" : data.aws_route53_zone.selected[0].zone_id
  crud_api_url                     = module.crud_api.invoke_url
  textract_api_url                 = var.textract_api == "" ? "" : module.textract_api[0].invoke_url
  image_upload_bucket_regional_url = var.textract_api == "" ? "" : module.textract_api[0].bucket_regional_domain_name
}
