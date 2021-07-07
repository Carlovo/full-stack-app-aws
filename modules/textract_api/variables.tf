variable "log_apis" {
  type        = bool
  default     = false
  description = "Log API Gateway (V2) requests and reponses. A role to do so must be configured in the AWS region, see api_gateway_log_role."
}

variable "alternate_domain_name" {
  type        = string
  default     = ""
  description = "Domain name of a HostedZone created by the Route53 Registrar, without trailing '.'"
}

variable "app_id" {
  type        = string
  description = "Consistent id for resources that need a unique name."
}

variable "api_rate_limit" {
  type = number
  # once enabled, throttling can't be disabled on api gateway v2, so just put something very high here
  default     = 5000
  description = "The maximum number of requests per second the API is allowed to respond to."
}

locals {
  alias_domain_name = "textract-api.${var.alternate_domain_name}"
  # Necessary to prevent cyclic dependencies
  crud_stage_name = "crud"
}
