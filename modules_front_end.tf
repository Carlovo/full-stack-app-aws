module "front_end" {
  source = "./modules/crud_app_front_end"

  tables                           = var.tables
  insecure                         = var.insecure
  alternate_domain_name            = var.alternate_domain_name
  route53_zone_id                  = var.alternate_domain_name == "" ? "" : data.aws_route53_zone.selected[0].zone_id
  crud_api_url                     = var.alternate_domain_name == "" ? "https://${aws_api_gateway_stage.crud.invoke_url}/" : "https://${aws_route53_record.crud_api_alias[0].name}/"
  textract_api_url                 = var.textract_api == "" ? "" : module.textract_api[0].invoke_url
  image_upload_bucket_regional_url = var.textract_api == "" ? "" : module.textract_api[0].bucket_regional_domain_name
}
