# although most resources in the module are stateless,
# its primary function is serving persistant storage
module "dynamodb_api_gateway_data_tier" {
  for_each = var.tables

  source = "../dynamodb_api_gateway_data_tier"

  unique_name_prefix      = var.unique_name_prefix
  table                   = each.key
  api_gateway_rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id               = aws_api_gateway_rest_api.this.root_resource_id
}
