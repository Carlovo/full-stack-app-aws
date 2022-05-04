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

module "front_end" {
  source = "./modules/crud_app_front_end"

  alternate_domain_name                   = local.alternate_domain_name
  insecure                                = local.insecure
  tables                                  = local.tables
  crud_api_url                            = module.crud_api.full_invoke_url
  textract_api_url                        = local.textract_api ? module.textract_api[0].full_invoke_url : ""
  image_upload_bucket_url                 = local.textract_api ? module.textract_api[0].bucket_full_regional_url : ""
  app_id                                  = local.app_id
  crud_api_key                            = local.crud_api_daily_usage_quota > 0 ? module.crud_api.usage_key : ""
  app_landing_page_name                   = local.app_landing_page_name
  redirect_missing_file_extension_to_html = local.redirect_missing_file_extension_to_html
}
