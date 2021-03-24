output "api_url" {
  value = aws_api_gateway_deployment.main.invoke_url
}

output "cloudfront_endpoint" {
  value = aws_cloudfront_distribution.front_end.domain_name
}

output "insecure_only_s3_endpoint" {
  value = aws_s3_bucket.front_end.bucket_regional_domain_name
}
