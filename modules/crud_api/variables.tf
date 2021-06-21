variable "tables" {
  type        = set(string)
  default     = ["default"]
  description = "List of unique names (set of strings) for which the CRUD app will create a separate table."
}

variable "log_apis" {
  type        = bool
  default     = false
  description = "Log API Gateway (V2) requests and reponses. A role to do so must be configured in the AWS region, see api_gateway_log_role."
}

variable "api_gateway_log_role" {
  type        = bool
  default     = false
  description = "Create and set a role in this AWS region to log requests through API Gateway, careful, there can only be one."
}

variable "unique_name_prefix" {
  type        = string
  description = "String to prefex resource names with to make them unique."
}

variable "alternate_domain_information" {
  type = object({
    domain_name         = string
    route53_zone_id     = string
    acm_certificate_arn = string
  })
  description = "Information necessary to deploy the API behind a custom domain name."
}

locals {
  # Necessary to prevent cyclic dependencies
  crud_stage_name = "crud"
}

data "aws_region" "current" {}
