output "invoke_url" {
  value = var.alternate_domain_information["domain_name"] == "" ? aws_apigatewayv2_stage.textract.invoke_url : aws_route53_record.textract_api_alias[0].name
}

output "bucket_regional_domain_name" {
  value = "https://${aws_s3_bucket.image_uploads.bucket_regional_domain_name}/"
}
