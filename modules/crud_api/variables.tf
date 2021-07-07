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

variable "app_id" {
  type        = string
  description = "Consistent id for resources that need a unique name."
}

variable "alternate_domain_name" {
  type        = string
  default     = ""
  description = "Domain name of a HostedZone created by the Route53 Registrar, without trailing '.'"
}

variable "api_rate_limit" {
  type = number
  # disable throttling
  default     = -1
  description = "The maximum number of requests per second the API is allowed to respond to."
}

locals {
  alias_domain_name = "crud-api.${var.alternate_domain_name}"
  # Necessary to prevent cyclic dependencies
  crud_stage_name = "crud"
}
