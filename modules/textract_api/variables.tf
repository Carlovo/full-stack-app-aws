variable "log_apis" {
  type        = bool
  default     = false
  description = "Log API Gateway (V2) requests and reponses. A role to do so must be configured in the AWS region, see api_gateway_log_role."
}

variable "alternate_domain_information" {
  type = object({
    domain_name         = string
    route53_zone_id     = string
    acm_certificate_arn = string
  })
  description = "Information necessary to deploy the API behind a custom domain name."
}
