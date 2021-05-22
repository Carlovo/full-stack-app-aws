output "api_gateway_crud_invoke_url" {
  value = aws_api_gateway_deployment.crud.invoke_url
}

output "apigatewayv2_s3_presign_invoke_url" {
  value = aws_apigatewayv2_stage.s3_presign.invoke_url
}

output "cloudfront_endpoint" {
  value = aws_cloudfront_distribution.front_end.domain_name
}

output "insecure_only_s3_endpoint" {
  value = aws_s3_bucket.front_end.bucket_regional_domain_name
}
