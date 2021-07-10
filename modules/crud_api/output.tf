output "full_invoke_url" {
  value = var.alternate_domain_name == "" ? "${aws_api_gateway_stage.this.invoke_url}/" : "https://${aws_route53_record.this[0].name}/"
}

output "usage_key" {
  value     = var.daily_usage_quota > 0 ? aws_api_gateway_api_key.this[0].value : "only available when deploying with -var='daily_usage_quote=#'"
  sensitive = true
}
