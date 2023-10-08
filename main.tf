# Create a consistent id for resources that need a unique name.
resource "random_string" "id" {
  count = local.alternate_domain_name == "" ? 1 : 0

  length  = 12
  upper   = false
  special = false
}

locals {
  app_id = local.alternate_domain_name == "" ? "crud-${random_string.id[0].id}" : "crud-${replace(local.alternate_domain_name, ".", "-")}"
}

module "crud_api" {
  source = "./modules/crud_api"

  alternate_domain_name = local.alternate_domain_name
  tables                = local.tables
  log_apis              = local.log_apis
  api_gateway_log_role  = local.api_gateway_log_role
  app_id                = local.app_id
  api_rate_limit        = local.apis_rate_limit
  daily_usage_quota     = local.crud_api_daily_usage_quota
}

module "textract_api" {
  count = local.textract_api ? 1 : 0

  source = "./modules/textract_api"

  alternate_domain_name = local.alternate_domain_name
  log_apis              = local.log_apis
  app_id                = local.app_id
  # once enabled, throttling can't be disabled on api gateway v2, so just put something very high here
  api_rate_limit = local.apis_rate_limit == -1 ? 5000 : local.apis_rate_limit
}

locals {
  subject_alternative_names = local.alternate_domain_name == "" ? [] : [local.alternate_domain_name, "www.${local.alternate_domain_name}"]
}

data "aws_route53_zone" "selected" {
  count = local.alternate_domain_name == "" ? 0 : 1

  name = local.alternate_domain_name
}

module "certificate_and_validation" {
  count = local.alternate_domain_name == "" ? 0 : 1

  source = "github.com/Carlovo/acm-certificate-route53-validation"

  # CloudFront accepts only ACM certificates from US-EAST-1
  providers = { aws = aws.useast1 }

  domain_names = local.subject_alternative_names
  zone_id      = data.aws_route53_zone.selected[0].zone_id
}

module "cdn" {
  source = "github.com/Carlovo/cloudfront-s3"

  bucket_name                             = "${local.app_id}-front-end"
  domain_name                             = local.alternate_domain_name
  us_east_1_acm_certificate_arn           = local.alternate_domain_name == "" ? "" : module.certificate_and_validation[0].acm_certificate_arn
  subject_alternative_names               = local.subject_alternative_names
  cloudfront_function_viewer_request_code = local.redirect_missing_file_extension_to_html ? file("${path.module}/modules/redirect_missing_file_extension_to_html.js") : ""
  log_requests                            = local.log_cdn_requests
}

module "front_end" {
  source = "./modules/crud_app_front_end_content"

  bucket_name             = module.cdn.bucket_id
  tables                  = local.tables
  crud_api_url            = module.crud_api.full_invoke_url
  textract_api_url        = local.textract_api ? module.textract_api[0].full_invoke_url : ""
  image_upload_bucket_url = local.textract_api ? module.textract_api[0].bucket_full_regional_url : ""
  crud_api_key            = local.crud_api_daily_usage_quota > 0 ? module.crud_api.usage_key : ""
  app_landing_page_name   = local.app_landing_page_name
}
