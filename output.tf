output "api_url" {
  value = aws_api_gateway_deployment.minimal.invoke_url
}

output "cloudfront_endpoint" {
  value = aws_cloudfront_distribution.minimal_distribution.domain_name
}
