variable "tables" {
  type        = set(string)
  description = "List of unique names (set of strings) for which the front end will show query options."
}

variable "insecure" {
  type        = bool
  default     = false
  description = "Prevent exclusive CloudFront access to content S3 bucket. Useful for faster development."
}

variable "alternate_domain_name" {
  type        = string
  default     = ""
  description = "Domain name of a HostedZone created by the Route53 Registrar, without trailing '.'"
}

variable "route53_zone_id" {
  type        = string
  default     = ""
  description = "ID of the Route53 hosted zone of the alternate domain name."
}

variable "crud_api_url" {
  type        = string
  description = "URL of the CRUD API."
}

variable "textract_api_url" {
  type        = string
  default     = ""
  description = "URL of Textract API, may be omitted if Textract API is not deployed."
}

variable "image_upload_bucket_url" {
  type        = string
  default     = ""
  description = "Regional URL of the bucket for image uploads, may be omitted if Textract API not deployed."
}

variable "app_id" {
  type        = string
  description = "Consistent id for resources that need a unique name."
}

locals {
  alternate_domain_names = var.alternate_domain_name == "" ? [] : [var.alternate_domain_name, "www.${var.alternate_domain_name}"]
}
