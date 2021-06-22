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
