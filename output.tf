output "api_url" {
  value = aws_api_gateway_deployment.minimal.invoke_url
}

output "website_endpoint" {
  value = aws_s3_bucket.minimal_frontend_bucket.website_endpoint
}

output "cloudfront_endpoint" {
  value = aws_cloudfront_distribution.minimal_distribution.domain_name
}

output "name" {
  value = aws_s3_bucket.minimal_frontend_bucket.bucket_regional_domain_name
}
