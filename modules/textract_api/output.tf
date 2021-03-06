output "full_invoke_url" {
  value = var.alternate_domain_name == "" ? aws_apigatewayv2_stage.this.invoke_url : "https://${aws_route53_record.this[0].fqdn}/"
}

output "bucket_full_regional_url" {
  value = "https://${aws_s3_bucket.image_uploads.bucket_regional_domain_name}/"
}
