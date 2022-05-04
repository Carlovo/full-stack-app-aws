variable "alternate_domain_name" {
  type        = string
  default     = null
  description = "Domain name of a HostedZone created by the Route53 Registrar, without trailing '.'"
}

variable "insecure" {
  type        = bool
  default     = null
  description = "Prevent exclusive CloudFront access to content S3 bucket. Useful for faster development."
}

variable "tables" {
  type        = set(string)
  default     = null
  description = "List of unique names (set of strings) for which the CRUD app will create a separate table."
}

variable "log_apis" {
  type        = bool
  default     = null
  description = "Log API Gateway (V2) requests and reponses. A role to do so must be configured in the AWS region, see api_gateway_log_role."
}

variable "api_gateway_log_role" {
  type        = bool
  default     = null
  description = "Create and set a role in this AWS region to log requests through API Gateway, careful, there can only be one."
}

variable "textract_api" {
  type        = bool
  default     = null
  description = "Should a Textract API be deployed?"
}

variable "apis_rate_limit" {
  type        = number
  default     = null
  description = "The maximum number of requests per second the APIs are allowed to respond to."
}

variable "crud_api_daily_usage_quota" {
  type        = number
  default     = null
  description = "The maximum number of requests per day the CRUD API is allowed to respond to, makes API key usage compulsory."
}

variable "app_landing_page_name" {
  type        = string
  default     = null
  description = "The URI resource name of app front end page."
}

variable "redirect_missing_file_extension_to_html" {
  type        = bool
  default     = null
  description = "Redirect users querying for resource without a file extension (or just . or /) to .html."
}

variable "workspace_variables" {
  type = map(object({
    alternate_domain_name                   = string
    insecure                                = bool
    tables                                  = set(string)
    log_apis                                = bool
    api_gateway_log_role                    = bool
    textract_api                            = bool
    apis_rate_limit                         = number
    crud_api_daily_usage_quota              = number
    app_landing_page_name                   = string
    redirect_missing_file_extension_to_html = bool
  }))
  default = {}
}

locals {
  default_vars = lookup(var.workspace_variables, terraform.workspace, {
    alternate_domain_name                   = ""
    insecure                                = false
    tables                                  = ["default"]
    log_apis                                = false
    api_gateway_log_role                    = false
    textract_api                            = false
    apis_rate_limit                         = -1 # disable throttling
    crud_api_daily_usage_quota              = 0  # no quote
    app_landing_page_name                   = "index.html"
    redirect_missing_file_extension_to_html = false
  })
  alternate_domain_name                   = var.alternate_domain_name != null ? var.alternate_domain_name : local.default_vars["alternate_domain_name"]
  insecure                                = var.insecure != null ? var.insecure : local.default_vars["insecure"]
  tables                                  = var.tables != null ? var.tables : local.default_vars["tables"]
  log_apis                                = var.log_apis != null ? var.log_apis : local.default_vars["log_apis"]
  api_gateway_log_role                    = var.api_gateway_log_role != null ? var.api_gateway_log_role : local.default_vars["api_gateway_log_role"]
  textract_api                            = var.textract_api != null ? var.textract_api : local.default_vars["textract_api"]
  apis_rate_limit                         = var.apis_rate_limit != null ? var.apis_rate_limit : local.default_vars["apis_rate_limit"]
  crud_api_daily_usage_quota              = var.crud_api_daily_usage_quota != null ? var.crud_api_daily_usage_quota : local.default_vars["crud_api_daily_usage_quota"]
  app_landing_page_name                   = var.app_landing_page_name != null ? var.app_landing_page_name : local.default_vars["app_landing_page_name"]
  redirect_missing_file_extension_to_html = var.redirect_missing_file_extension_to_html != null ? var.redirect_missing_file_extension_to_html : local.default_vars["redirect_missing_file_extension_to_html"]
}
