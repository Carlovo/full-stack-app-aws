output "crud_api_invoke_url" {
  value = var.alternate_domain_name == "" ? aws_api_gateway_stage.crud.invoke_url : aws_route53_record.crud_api_alias[0].name
}

output "textract_api_invoke_url" {
  value = var.textract_api ? module.textract_api[0].invoke_url : "only available when deploying with -var='textract_api=true'"
}

output "cloudfront_endpoint" {
  value = module.front_end.cloudfront_endpoint
}

output "insecure_only_s3_endpoint" {
  value = module.front_end.insecure_only_s3_endpoint
}
