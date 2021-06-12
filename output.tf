output "crud_api_invoke_url" {
  value = var.alternate_domain_name == "" ? aws_api_gateway_deployment.crud.invoke_url : aws_route53_record.crud_api_alias[0].name
}

output "upload_api_invoke_url" {
  value = var.alternate_domain_name == "" ? aws_apigatewayv2_stage.s3_presign.invoke_url : aws_route53_record.upload_api_alias[0].name
}

output "cloudfront_endpoint" {
  value = aws_cloudfront_distribution.front_end.domain_name
}

output "insecure_only_s3_endpoint" {
  value = var.insecure ? aws_s3_bucket.front_end.bucket_regional_domain_name : "only available when deploying with -var='insecure=true'"
}
