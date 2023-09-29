output "cloudfront_endpoint" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "bucket_id" {
  value = aws_s3_bucket.this.id
}
