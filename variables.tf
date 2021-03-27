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

locals {
  front_end_alternate_domain_names = var.alternate_domain_name == "" ? [] : [var.alternate_domain_name, "www.${var.alternate_domain_name}"]
  back_end_alternate_domain_name = "api.${var.alternate_domain_name}"
  # Using the full S3 bucket name would make a too long name for DynamoDB
  unique_name_prefix = "tf-${split("-", aws_s3_bucket.front_end.id)[1]}-"
}
