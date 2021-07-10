output "crud_api_invoke_url" {
  value = module.crud_api.full_invoke_url
}

output "textract_api_invoke_url" {
  value = var.textract_api ? module.textract_api[0].full_invoke_url : "only available when deploying with -var='textract_api=true'"
}

output "cloudfront_endpoint" {
  value = module.front_end.cloudfront_endpoint
}

output "insecure_only_s3_endpoint" {
  value = module.front_end.insecure_only_s3_endpoint
}

output "crud_api_key" {
  value     = var.crud_api_daily_usage_quota > 0 ? module.crud_api.usage_key : "only available when deploying with -var='crud_api_daily_usage_quote=#'"
  sensitive = true
}
