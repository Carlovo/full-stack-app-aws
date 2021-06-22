module "crud_api" {
  source = "./modules/crud_api"

  alternate_domain_name = var.alternate_domain_name
  tables                = var.tables
  log_apis              = var.log_apis
  api_gateway_log_role  = var.api_gateway_log_role
  unique_name_prefix    = local.unique_name_prefix
}

module "textract_api" {
  count = var.textract_api ? 1 : 0

  source = "./modules/textract_api"

  alternate_domain_name = var.alternate_domain_name
  log_apis              = var.log_apis
}

module "front_end" {
  source = "./modules/crud_app_front_end"

  alternate_domain_name   = var.alternate_domain_name
  insecure                = var.insecure
  tables                  = var.tables
  crud_api_url            = module.crud_api.full_invoke_url
  textract_api_url        = var.textract_api == "" ? "" : module.textract_api[0].full_invoke_url
  image_upload_bucket_url = var.textract_api == "" ? "" : module.textract_api[0].bucket_full_regional_url
}

locals {
  # Using the full S3 bucket name would make a too long name for DynamoDB
  unique_name_prefix = "tf-${split("-", module.front_end.bucket_id)[1]}-"
}
