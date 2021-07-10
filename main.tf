# Create a consistent id for resources that need a unique name.
resource "random_string" "id" {
  count = var.alternate_domain_name == "" ? 1 : 0

  length  = 12
  upper   = false
  special = false
}

locals {
  app_id = var.alternate_domain_name == "" ? "crud-${random_string.id[0].id}" : "crud-${replace(var.alternate_domain_name, ".", "-")}"
}

module "crud_api" {
  source = "./modules/crud_api"

  alternate_domain_name = var.alternate_domain_name
  tables                = var.tables
  log_apis              = var.log_apis
  api_gateway_log_role  = var.api_gateway_log_role
  app_id                = local.app_id
  api_rate_limit        = var.apis_rate_limit
  daily_usage_quota     = var.crud_api_daily_usage_quota
}

module "textract_api" {
  count = var.textract_api ? 1 : 0

  source = "./modules/textract_api"

  alternate_domain_name = var.alternate_domain_name
  log_apis              = var.log_apis
  app_id                = local.app_id
  # once enabled, throttling can't be disabled on api gateway v2, so just put something very high here
  api_rate_limit = var.apis_rate_limit == -1 ? 5000 : var.apis_rate_limit
}

module "front_end" {
  source = "./modules/crud_app_front_end"

  alternate_domain_name   = var.alternate_domain_name
  insecure                = var.insecure
  tables                  = var.tables
  crud_api_url            = module.crud_api.full_invoke_url
  textract_api_url        = var.textract_api ? module.textract_api[0].full_invoke_url : ""
  image_upload_bucket_url = var.textract_api ? module.textract_api[0].bucket_full_regional_url : ""
  app_id                  = local.app_id
  crud_api_key            = var.crud_api_daily_usage_quota > 0 ? module.crud_api.usage_key : ""
}
