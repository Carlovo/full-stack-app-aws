# although most resources in the module are stateless,
# its primary function is serving persistant storage
module "dynamodb_api_gateway_data_tier" {
  for_each = var.tables

  source = "../dynamodb_api_gateway_data_tier"

  app_id                  = var.app_id
  table                   = each.key
  api_gateway_rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id               = aws_api_gateway_rest_api.this.root_resource_id
  enforce_api_key         = var.daily_usage_quota > 0
}
