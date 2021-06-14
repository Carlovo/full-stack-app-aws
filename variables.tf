variable "alternate_domain_name" {
  type        = string
  default     = ""
  description = "Domain name of a HostedZone created by the Route53 Registrar, without trailing '.'"
}

variable "insecure" {
  type        = bool
  default     = false
  description = "Prevent exclusive CloudFront access to content S3 bucket. Useful for faster development."
}

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

locals {
  alternate_domain_names = var.alternate_domain_name == "" ? {} : {
    front_end = {
      apex = var.alternate_domain_name
      www  = "www.${var.alternate_domain_name}"
    }
    back_end = {
      crud_api   = "crud-api.${var.alternate_domain_name}"
      upload_api = "upload-api.${var.alternate_domain_name}"
    }
  }
  # Necessary to prevent cyclic dependencies
  crud_stage_name = "crud"
  # Using the full S3 bucket name would make a too long name for DynamoDB
  unique_name_prefix = "tf-${split("-", aws_s3_bucket.front_end.id)[1]}-"
}

data "aws_region" "current" {}
