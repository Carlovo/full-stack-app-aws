output "cloudfront_endpoint" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "insecure_only_s3_endpoint" {
  value = var.insecure ? aws_s3_bucket.this.bucket_regional_domain_name : "only available when deploying with -var='insecure=true'"
}

output "bucket_id" {
  value = aws_s3_bucket.this.id
}
