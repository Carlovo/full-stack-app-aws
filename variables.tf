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

variable "apps" {
  type        = set(string)
  default     = ["app"]
  description = "List of unique names (set of strings) for which a CRUD app (front + back end) will be created."
}

locals {
  alternate_domain_names = var.alternate_domain_name == "" ? [] : [var.alternate_domain_name, "www.${var.alternate_domain_name}"]
}
