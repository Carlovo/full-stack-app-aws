output "api_url" {
  value = aws_api_gateway_deployment.minimal.invoke_url
}

output "cloudfront_endpoint" {
  value = aws_cloudfront_distribution.minimal_distribution.domain_name
}

output "insecure_only_s3_endpoint" {
  value = aws_s3_bucket.minimal_frontend_bucket.bucket_regional_domain_name
}
