output "full_invoke_url" {
  value = var.alternate_domain_name == "" ? "${aws_api_gateway_stage.this.invoke_url}/" : "https://${aws_route53_record.this[0].name}/"
}
