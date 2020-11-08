output "api_url" {
  value = module.app_back_end
}

output "cloudfront_endpoint" {
  value = aws_cloudfront_distribution.front_end.domain_name
}

output "insecure_only_s3_endpoint" {
  value = aws_s3_bucket.front_end.bucket_regional_domain_name
}
